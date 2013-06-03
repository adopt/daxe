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
 * This class presents a mathematical square root
 */
class MathSqrt extends MathElement {

  /** The XML element from this class */
  static final String ELEMENT = "msqrt";

  
  MathSqrt() : super();
  
  
  @override
  void paint(final h.CanvasRenderingContext2D context, final double posX, final double posY) {
    final double width = getWidth(true);

    final double width1 = getMathElementsWidth();
    //double height1 = getMathElementsHeight(true);
    final double height1 = 8.0;
    final double aheight1 = getMathElementsAscentHeight(true);
    final double dheight1 = getMathElementsDescentHeight(true);
    
    context.beginPath();
    
    context.moveTo(posX, posY);
    context.lineTo(posX + 3, posY - 1);
    
    context.moveTo(posX + 3, posY);
    context.lineTo(posX + height1 / 2 + 1, posY + dheight1);
    
    context.moveTo(posX + 2, posY - 1);
    context.lineTo(posX + height1 / 2 + 1, posY + dheight1);
    
    context.moveTo(posX + height1 / 2 + 1, posY + dheight1);
    context.lineTo(posX + height1 + 3, posY - (aheight1 + 1));
    
    context.moveTo(posX + height1 + 3, posY - (aheight1 + 1));
    context.lineTo(posX + width, posY - (aheight1 + 1));
    
    context.stroke();
    
    double pos = posX + height1 + 3;
    MathElement child;

    for (int i = 0; i < getMathElementCount(); i++) {
      child = getMathElement(i);
      child.paint(context, pos, posY);
      pos += child.getWidth(true);
    }
  }

  /**
   * Returns the width of the children
   *
   * @return Width of childs
   */
  double getMathElementsWidth() {
    double width = 0.0;

    for (int i = 0; i < getMathElementCount(); i++)
      width += getMathElement(i).getWidth(true);
    return width;
  }

  @override
  double getWidth(final bool dynamicParts) {
    //return getMathElementsWidth() + getMathElementsHeight(true) + 2;
    return getMathElementsWidth() + 8 + 3;
  }

  /**
   * Returns the maximal height of the children
   *
   * @param dynamicParts Should be true, if the calculation consider the elements,
   *                     which has not fixed sizes
   *
   * @return Maximal height of children
   */
  double getMathElementsHeight(final bool dynamicParts) {
    double height = 0.0;

    for (int i = 0; i < getMathElementCount(); i++)
      height = max(height, getMathElement(i).getHeight(true));
    
    return height;
  }

  @override
  double getHeight(final bool dynamicParts) {
    return getMathElementsHeight(true) + 4;
  }

  /**
   * Return the maximal height of the upper part from the children 
   *
   * @param dynamicParts Should be true, if the calculation consider the elements,
   *                     which has not fixed sizes
   *
   * @return Maximal height of the upper parts from the children
   */
  double getMathElementsAscentHeight(final bool dynamicParts) {
    double height = 0.0;

    for (int i = 0; i < getMathElementCount(); i++)
      height = max(height, getMathElement(i).getAscentHeight(true));
    
    return height;
  }

  @override
  double getAscentHeight(final bool dynamicParts) {
    return getMathElementsAscentHeight(true) + 2;
  }

/**
 * Return the maximal height of the lower part from the children 
 *
 * @param dynamicParts Should be true, if the calculation consider the elements,
 *                     which has not fixed sizes
 *
 * @return Maximal height of the lower parts from the children
 */
  double getMathElementsDescentHeight(final bool dynamicParts) {
    double height = 0.0;

    for (int i = 0; i < getMathElementCount(); i++)
      height = max(height, getMathElement(i).getDescentHeight(true));
    return height;
  }

  @override
  double getDescentHeight(final bool dynamicParts) {
    return getMathElementsDescentHeight(true) + 2;
  }
  
}

