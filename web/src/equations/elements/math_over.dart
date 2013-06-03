/*
  This file is part of Daxe.

  Daxe is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Daxe is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Daxe.  If not, see <http://www.gnu.org/licenses/>.
*/

part of equations;

/**
 * This class arrange a element over an other element
 */
class MathOver extends MathElement {

  /** The XML element from this class */
  static final String ELEMENT = "mover";
  
  bool _accent = false;

  
  MathOver() : super();
  

  @override
  void addMathElement(final MathElement child) {
    super.addMathElement(child);
    if (child != null) {
      if (getMathElementCount() == 2 && !_accent)
        child.setFontSize(getFontSize() - 2);
      else
        child.setFontSize(getFontSize());
    }
  }

  @override
  void setFontSize(final int fontsize) {
    super.setFontSize(fontsize);
    if (getMathElement(1) != null && !_accent)
        getMathElement(1).setFontSize(getFontSize()-2);
  }

  @override
  void paint(final h.CanvasRenderingContext2D context, final double posX, final double posY) {
    final MathElement e1 = getMathElement(0);
    final MathElement e2 = getMathElement(1);

    final double width = getWidth(true);

    e1.paint(context, posX + (width - e1.getWidth(true)) / 2, posY);
    if (_accent) {
      double h;
      if (e1 is MathText || e1 is MathIdentifier)
        h = e1.getRealAscentHeight() + 3;
      else
        h = e1.getAscentHeight(true);
      e2.paint(context, posX + (width - e2.getWidth(true)) / 2,
          posY - h);
    } else
      e2.paint(context, posX + (width - e2.getWidth(true)) / 2,
          posY - (e1.getAscentHeight(true) + e2.getDescentHeight(true)));
  }

  @override
  double getWidth(final bool dynamicParts) {
    return max(getMathElement(0).getWidth(dynamicParts),
               getMathElement(1).getWidth(dynamicParts));
  }

  @override
  double getHeight(final bool dynamicParts) {
    if (_accent)
      return getMathElement(0).getHeight(dynamicParts) + getMathElement(1).getAscentHeight(dynamicParts) + 1;
    else
      return getMathElement(0).getHeight(dynamicParts) + getMathElement(1).getHeight(dynamicParts);
  }

  @override
  double getAscentHeight(final bool dynamicParts) {
    if (_accent)
      return getMathElement(0).getAscentHeight(true) + getMathElement(1).getAscentHeight(true);
    else
      return getMathElement(0).getAscentHeight(true) + getMathElement(1).getHeight(true);
  }

  @override
  double getDescentHeight(final bool dynamicParts) {
    return getMathElement(0).getDescentHeight(true);
  }
  
  void setAccent(final bool accent) {
    this._accent = accent;
  }
  
  bool getAccent() {
    return _accent;
  }
  
}

