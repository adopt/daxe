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
 * This class arrange an element lower to an other element
 */
class MathSup extends MathElement {

  /** The XML element from this class */
  static final String ELEMENT = "msup";

  
  MathSup() : super();
  
  
  /**
   * Add a math element as a child
   *
   * @param child Math element
   */
  @override
  void addMathElement(final MathElement child) {
    super.addMathElement(child);
    if (child != null) {
      if (getMathElementCount() == 2)
        child.setFontSize(getFontSize() - 2);
      else
        child.setFontSize(getFontSize());
    }
  }

  /**
   * Sets the font size for this component
   *
   * @param fontsize Font size
   */
  @override
  void setFontSize(final int fontsize) {
    super.setFontSize(fontsize);
    if (getMathElement(1) != null)
      getMathElement(1).setFontSize(getFontSize()-2);
  }

  @override
  void paint(final h.CanvasRenderingContext2D context, final double posX, final double posY) {
    final MathElement e1 = getMathElement(0);
    final MathElement e2 = getMathElement(1);

    e1.paint(context, posX, posY);
    e2.paint(context, posX + e1.getWidth(true),
        posY - max(e2.getDescentHeight(true) + getMiddleShift(),
                   e1.getAscentHeight(true) - e2.getDescentHeight(true)));
  }

  @override
  double getWidth(final bool dynamicParts) {
    return getMathElement(0).getWidth(dynamicParts) +
        getMathElement(1).getWidth(dynamicParts);
  }

  @override
  double getHeight(final bool dynamicParts) {
    return getAscentHeight(true) + getDescentHeight(true);
  }

  @override
  double getAscentHeight(final bool dynamicParts) {
    final MathElement e1 = getMathElement(0);
    final MathElement e2 = getMathElement(1);
    return(e2.getAscentHeight(true) + max(e2.getDescentHeight(true) + getMiddleShift(),
                                          e1.getAscentHeight(true) - e2.getDescentHeight(true)));
  }

  @override
  double getDescentHeight(final bool dynamicParts) {
    return getMathElement(0).getDescentHeight(true);
  }
  
}

