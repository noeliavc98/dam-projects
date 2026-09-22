enum Nivel10Layout { mobile, tablet, desktop }

Nivel10Layout nivel10LayoutFor(double width) {
  if (width < 700) return Nivel10Layout.mobile;
  if (width < 1100) return Nivel10Layout.tablet;
  return Nivel10Layout.desktop;
}

bool nivel10IsCompact(double width) {
  return nivel10LayoutFor(width) != Nivel10Layout.desktop;
}
