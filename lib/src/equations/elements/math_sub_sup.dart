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
 * This class arange a element lower, and a other
 * elements upper to an element
 */
class MathSubSup extends MathElement {

  /** The XML element from this class */
  static final String ELEMENT = "msubsup";

  
  MathSubSup() : super();
  

  @override
  void addMathElement(final MathElement child) {
    super.addMathElement(child);
    if (child != null) {
      if ((getMathElementCount() == 2) || (getMathElementCount() == 3))
        child.setFontSize(getFontSize() - 2);
      else
        child.setFontSize(getFontSize());
    }
  }

  @override
  void setFontSize(final int fontsize) {
    super.setFontSize(fontsize);
    if (getMathElement(1)!=null)
      getMathElement(1).setFontSize(getFontSize()-2);
    if (getMathElement(2)!=null)
      getMathElement(2).setFontSize(getFontSize()-2);
  }
  
  @override
  void paint(final h.CanvasRenderingContext2D context, final double posX, final double posY) {
    final MathElement e1 = getMathElement(0);
    final MathElement e2 = getMathElement(1);
    final MathElement e3 = getMathElement(2);

    // int middleshift = getMiddleShift();
    final double childmiddleshift = e2.getMiddleShift();
    // int posY1 = Math.max(posY+e2.getAscentHeight(true)-middleshift,
    // posY+e1.getDescentHeight(true)+middleshiftchild);
    // int posY2 = Math.min(posY-(e3.getAscentHeight(true)+middleshift),
    // posY-e1.getAscentHeight(true)+middleshiftchild);
    final double posY1 = posY + e1.getDescentHeight(true) + childmiddleshift / 2;
    final double posY2 = posY - e1.getAscentHeight(true) + childmiddleshift;

    e1.paint(context, posX, posY);
    e2.paint(context, posX + e1.getWidth(true), posY1);
    e3.paint(context, posX + e1.getWidth(true), posY2);
  }

  @override
  double getWidth(final bool dynamicParts) {
    return getMathElement(0).getWidth(dynamicParts)
        + max(getMathElement(1).getWidth(dynamicParts),
            getMathElement(2).getWidth(dynamicParts));
  }

  @override
  double getHeight(final bool dynamicParts) {
    return getAscentHeight(true) + getDescentHeight(true);
  }

  @override
  double getAscentHeight(final bool dynamicParts) {
    return max(getMathElement(0).getAscentHeight(true),
        getMathElement(2).getHeight(true) + getMiddleShift());
  }

  @override
  double getDescentHeight(final bool dynamicParts) {
    return max(getMathElement(0).getDescentHeight(true),
        getMathElement(1).getHeight(true) - getMiddleShift());
  }
  
}

