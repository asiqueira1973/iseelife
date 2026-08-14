// ManualCameraControls.swift
// Controles manuais da câmera (épico 8.2 — Modo Pro) e trava de foco/exposição por toque
// (épico 8.1 — Modo Rua). Cada setter usa lockForConfiguration no AVCaptureDevice ativo.
// Foco é exposto como lensPosition 0..1 — NÃO calibrado em metros (por isso zone focus com
// presets de distância fica fora do MVP, roadmap seção 28).

import AVFoundation

extension CameraSession {

    // Lê as faixas suportadas pela lente ativa para alimentar os sliders (critério 8.2).
    func lerRangesDoDispositivo(_ device: AVCaptureDevice) {
        let fmt = device.activeFormat
        DispatchQueue.main.async {
            self.isoRange = fmt.minISO...fmt.maxISO
            self.isoAtual = min(max(device.iso, fmt.minISO), fmt.maxISO)
            let minDur = CMTimeGetSeconds(fmt.minExposureDuration)
            let maxDur = CMTimeGetSeconds(fmt.maxExposureDuration)
            // Limita o teto do obturador a 1/30s para uso de mão livre em rua.
            self.duracaoObturadorRange = minDur...min(maxDur, 1.0/30.0)
            self.exposicaoEVRange = device.minExposureTargetBias...device.maxExposureTargetBias
            self.wbTemperatura = 5200
        }
    }

    // ISO manual (épico 8.2). Mantém a duração de obturador atual.
    func definirISO(_ iso: Float) {
        configurar { device in
            let clamped = min(max(iso, device.activeFormat.minISO), device.activeFormat.maxISO)
            device.setExposureModeCustom(duration: device.exposureDuration, iso: clamped)
            DispatchQueue.main.async { self.isoAtual = clamped }
        }
    }

    // Velocidade do obturador (épico 8.2). Mantém o ISO atual.
    func definirObturador(_ segundos: Double) {
        configurar { device in
            let dur = CMTime(seconds: segundos, preferredTimescale: 1_000_000)
            device.setExposureModeCustom(duration: dur, iso: AVCaptureDevice.currentISO)
            DispatchQueue.main.async { self.duracaoObturadorAtual = segundos }
        }
    }

    // Compensação de exposição em EV (épico 8.2).
    func definirExposicaoEV(_ ev: Float) {
        configurar { device in
            let clamped = min(max(ev, device.minExposureTargetBias), device.maxExposureTargetBias)
            device.setExposureTargetBias(clamped)
            DispatchQueue.main.async { self.exposicaoEV = clamped }
        }
    }

    // Foco manual via lensPosition 0..1 (épico 8.2).
    func definirFoco(_ posicao: Float) {
        configurar { device in
            guard device.isFocusModeSupported(.locked) else { return }
            let clamped = min(max(posicao, 0), 1)
            device.setFocusModeLocked(lensPosition: clamped)
            DispatchQueue.main.async { self.focoLensPosition = clamped }
        }
    }

    // White balance manual do sensor: temperatura (Kelvin) + tinta (épico 8.2).
    func definirWhiteBalance(temperatura: Float, tinta: Float) {
        configurar { device in
            guard device.isWhiteBalanceModeSupported(.locked) else { return }
            let tempTint = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(
                temperature: temperatura, tint: tinta)
            var gains = device.deviceWhiteBalanceGains(for: tempTint)
            let maxGain = device.maxWhiteBalanceGain
            gains.redGain = min(max(gains.redGain, 1), maxGain)
            gains.greenGain = min(max(gains.greenGain, 1), maxGain)
            gains.blueGain = min(max(gains.blueGain, 1), maxGain)
            device.setWhiteBalanceModeLocked(with: gains)
            DispatchQueue.main.async {
                self.wbTemperatura = temperatura
                self.wbTinta = tinta
            }
        }
    }

    // Trava foco e exposição no ponto tocado (épico 8.1 — Modo Rua). `ponto` normalizado 0..1
    // no espaço da imagem (x/y). O indicador visual "AE/AF LOCK" é responsabilidade da UI.
    func travarFocoExposicao(pontoNormalizado ponto: CGPoint) {
        configurar { device in
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = ponto
                if device.isFocusModeSupported(.autoFocus) { device.focusMode = .autoFocus }
            }
            // Sob prioridade de obturador (Rua), a exposição é governada pelo loop (obturador
            // fixo + ISO auto) — não trocar para autoExpose aqui, senão o loop é quebrado.
            if !shutterPriorityAtivo, device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = ponto
                if device.isExposureModeSupported(.autoExpose) { device.exposureMode = .autoExpose }
            }
        }
    }

    // Volta foco/exposição/WB para contínuo (ao sair do estado travado ou trocar de modo).
    func retomarAutoContinuo() {
        configurar { device in
            if device.isFocusModeSupported(.continuousAutoFocus) { device.focusMode = .continuousAutoFocus }
            if device.isExposureModeSupported(.continuousAutoExposure) { device.exposureMode = .continuousAutoExposure }
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }
        }
    }

    // Volta SÓ foco e WB para contínuo, sem tocar na exposição (v1.1). Usado no Modo Rua, onde a
    // exposição é governada pela prioridade de obturador — mas foco/WB manuais do Pro não devem
    // "grudar" ao voltar pro Rua nem ao trocar de receita.
    func resetarFocoWBContinuo() {
        configurar { device in
            if device.isFocusModeSupported(.continuousAutoFocus) { device.focusMode = .continuousAutoFocus }
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }
        }
    }

    // "Restaurar valores" do Modo Pro (v1.1): volta tudo pro automático contínuo e, após
    // estabilizar, lê os valores atuais do sensor de volta pros sliders.
    func restaurarAutomatico() {
        retomarAutoContinuo()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self, let d = self.dispositivoAtivo else { return }
            self.isoAtual = min(max(d.iso, d.activeFormat.minISO), d.activeFormat.maxISO)
            self.duracaoObturadorAtual = CMTimeGetSeconds(d.exposureDuration)
            self.exposicaoEV = d.exposureTargetBias
            self.focoLensPosition = d.lensPosition
            let tt = d.temperatureAndTintValues(for: d.deviceWhiteBalanceGains)
            self.wbTemperatura = tt.temperature
            self.wbTinta = tt.tint
        }
    }

    // Helper: executa um bloco de configuração com lockForConfiguration no device ativo.
    private func configurar(_ bloco: (AVCaptureDevice) -> Void) {
        guard let device = dispositivoAtivo else { return }
        do {
            try device.lockForConfiguration()
            bloco(device)
            device.unlockForConfiguration()
        } catch {
            // Falha de lock é silenciosa: mantém o último estado válido (sem crash em rua).
        }
    }
}
