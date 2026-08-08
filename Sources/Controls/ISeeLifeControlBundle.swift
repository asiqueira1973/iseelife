// ISeeLifeControlBundle.swift
// Ponto de entrada da extensão de Control (WidgetKit). Agrupa os Controls do I See Life.
// Hoje há um único Control (ShootControl — abrir e disparar no Modo Rua).

import WidgetKit
import SwiftUI

@main
struct ISeeLifeControlBundle: WidgetBundle {
    var body: some Widget {
        ShootControl()
    }
}
