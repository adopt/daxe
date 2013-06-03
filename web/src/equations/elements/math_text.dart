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
 * This class presents text in a equation
 */
class MathText extends MathElement {

  /** The XML element from this class */
  static final String ELEMENT = "mtext";

  MathText() : super();
  
  
  @override
  void paint(final h.CanvasRenderingContext2D context, final double posX, final double posY) {
    context.font = getFont();
    context.fillText(getText(), posX, posY);
  }

  @override
  double getWidth(final bool dynamicParts) {
    return stringWidth(getText().replaceAll(' ', 'A'));
  }

  @override
  double getHeight(final bool dynamicParts) {
    return getFontMetrics().ascent + getFontMetrics().descent;
  }
  
  double getRealAscentHeight() {
    TextMetrics metrics = getStringMetrics(getText());
    return(metrics.actualBoundingBoxAscent);
  }
  
  @override
  double getAscentHeight(final bool dynamicParts) {
    return getFontMetrics().ascent;
  }

  @override
  double getDescentHeight(final bool dynamicParts) {
    return getFontMetrics().descent;
  }
  
}

