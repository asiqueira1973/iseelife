// PermissionDeniedView.swift
// Tela de permissão negada (tela 08 / critério 8.5). Explica o que deixa de funcionar e leva
// a Ajustes do iOS. Serve para câmera (bloqueia o app) e para fotos (bloqueia o salvamento).

import SwiftUI

struct PermissionDeniedView: View {
    enum Tipo { case camera, fotos }
    let tipo: Tipo

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 20) {
                Spacer()
                Image(systemName: tipo == .camera ? "camera.fill.badge.ellipsis" : "photo.badge.exclamationmark")
                    .font(.system(size: 44, weight: .light)).foregroundStyle(.white)
                Text(L(tipo == .camera ? "denied_camera_title" : "denied_photos_title"))
                    .font(.system(size: 32, weight: .bold)).foregroundStyle(.white)
                Text(L(tipo == .camera ? "denied_camera_body" : "denied_photos_body"))
                    .font(.system(size: 19)).foregroundStyle(Estilo.textoSecundario)
                Spacer()
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "gearshape")
                        Text(L("denied_open_settings")).font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))
                }
            }
            .padding(.horizontal, 28).padding(.bottom, 40)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
