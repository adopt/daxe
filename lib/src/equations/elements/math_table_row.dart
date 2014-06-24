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
 * This class presents a row in MathTable
 */
class MathTableRow extends MathElement {

  /** The XML element from this class */
  static final String ELEMENT = "mtr";

  
  MathTableRow() : super();
  
  
  @override
  void paint(final h.CanvasRenderingContext2D context, final double posX, final double posY) {
    if (getMathBase().isDebug())
      debug(context, posX, posY);

    final double columnwidth = _getMaxColumnWidth();
    double pos = posX;

    for (int i = 0; i < getMathElementCount(); i++) {
      getMathElement(i).paint(context, pos, posY);
      pos += columnwidth;
    }
  }

  /**
   * Returns the maximal width of a column for all columns in this row
   *
   * @return width
   */
  double _getMaxColumnWidth() {
    double width = 0.0;

    for (int i = 0; i < getMathElementCount(); i++)
      width = max(width, getMathElement(i).getWidth(true));
    return width;
  }

  @override
  double getWidth(final bool dynamicParts) {
    return _getMaxColumnWidth() * getMathElementCount();
  }

  @override
  double getHeight(final bool dynamicParts) {
    double height = 0.0;

    for (int i = 0; i < getMathElementCount(); i++)
      height = max(height, getMathElement(i).getHeight(dynamicParts));
    return height;
  }

  @override
  double getAscentHeight(final bool dynamicParts) {
    double height = 0.0;

    for (int i = 0; i < getMathElementCount(); i++)
      height = max(height, getMathElement(i).getAscentHeight(dynamicParts));
    return height;
  }

  @override
  double getDescentHeight(final bool dynamicParts) {
    double height = 0.0;

    for (int i = 0; i < getMathElementCount(); i++)
      height = max(height, getMathElement(i).getDescentHeight(dynamicParts));
    return height;
  }
  
}

