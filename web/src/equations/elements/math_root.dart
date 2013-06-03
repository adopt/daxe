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
 * This class presents a mathematical root
 */
class MathRoot extends MathElement {

  /** The XML element from this class */
  static final String ELEMENT = "mroot";

  
  
  MathRoot() : super();
  
  
  @override
  void addMathElement(final MathElement child) {
    super.addMathElement(child);
    if (child != null)
    {
      if (getMathElementCount() == 2)
        child.setFontSize(getFontSize() - 2);
      else
        child.setFontSize(getFontSize());
    }
  }

  @override
  void setFontSize(final int fontsize) {
    super.setFontSize(fontsize);
    if (getMathElement(1) != null)
      getMathElement(1).setFontSize(getFontSize() - 2);
  }

  @override
  void paint(final h.CanvasRenderingContext2D context, final double posX, final double posY) {
    if (getMathElementCount() < 2)
      return;

    final MathElement e1 = getMathElement(0);
    final MathElement e2 = getMathElement(1);
    final double width = getWidth(true);

    final double width1 = e1.getWidth(true);
    //final int height1 = e1.getHeight(true);
    final double height1 = 8.0;
    final double width2 = e2.getWidth(true);
    final double height2 = e2.getHeight(true);

    final double aheight1 = e1.getAscentHeight(true);
    final double dheight1 = e1.getDescentHeight(true);
    
    context.beginPath();
    
    context.moveTo(posX, posY);
    context.lineTo(posX + width2, posY);
    
    context.moveTo(posX + width2, posY);
    context.lineTo(posX + height1 / 2 + width2, posY + dheight1);
    
    context.moveTo(posX + width2 - 1, posY);
    context.lineTo(posX + height1 / 2 + width2, posY + dheight1);
    
    context.moveTo(posX + height1 / 2 + width2, posY + dheight1);
    context.lineTo(posX + height1 + width2, posY - (aheight1 + 2));
    
    context.moveTo(posX + height1 + width2, posY - (aheight1 + 2));
    context.lineTo(posX + width, posY - (aheight1 + 2));
    
    context.stroke();
    
    e1.paint(context, posX + height1 + width2, posY);
    e2.paint(context, posX, posY - e2.getDescentHeight(true));
  }

  @override
  double getWidth(final bool dynamicParts) {
    if (getMathElementCount() < 2)
      return 0.0;

    //return getMathElement(0).getWidth(dynamicParts) + getMathElement(0).getHeight(true) + getMathElement(1).getWidth(dynamicParts);
    return getMathElement(0).getWidth(dynamicParts) + 8 + getMathElement(1).getWidth(dynamicParts);
  }

  @override
  double getHeight(final bool dynamicParts) {
    if (getMathElementCount() < 2)
      return 0.0;

    return getDescentHeight(true)
        + max(getMathElement(0).getAscentHeight(true) + 4,
            getMathElement(1).getHeight(true));
  }

  @override
  double getAscentHeight(final bool dynamicParts) {
    if (getMathElementCount() < 2)
      return 0.0;

    return max(getMathElement(0).getAscentHeight(true) + 4,
        getMathElement(1).getHeight(true));
  }

  @override
  double getDescentHeight(final bool dynamicParts) {
    if (getMathElementCount() < 2)
      return 0.0;

    return getMathElement(0).getDescentHeight(true);
  }
  
}

