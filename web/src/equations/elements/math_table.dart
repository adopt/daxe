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
 * This class presents a table
 */
class MathTable extends MathElement {

  /** The XML element from this class */
  static final String ELEMENT = "mtable";

  
  MathTable() : super();
  
  
  @override
  void paint(final h.CanvasRenderingContext2D context, final double posX, final double posY) {
    // debug(g, posX, posY);

    int i, j;
    final List<double> maxrowascentheight = new List<double>(getMathElementCount());
    final List<double> maxrowdescentheight = new List<double>(getMathElementCount());

    for (i = 0; i < getMathElementCount(); i++) {
      maxrowascentheight[i] = getMaxRowAscentHeight(i);
      maxrowdescentheight[i] = getMaxRowDescentHeight(i);
    }

    final int maxcolumns = getMaxColumnCount();
    final List<double> maxcolumnwidth = new List<double>(maxcolumns);

    for (i = 0; i < maxcolumns; i++)
      maxcolumnwidth[i] = getMaxColumnWidth(i);

    final double x1 = posX;
    final double y1 = -getHeight(true) / 2 + maxrowascentheight[0] - getMiddleShift();

    double x = x1;
    double y = y1;

    for (i = 0; i < getMathElementCount(); i++) {
      final MathElement row = getMathElement(i);

      x = x1;
      for (j = 0; (j < maxcolumns) && (j < row.getMathElementCount()); j++) {
        // row.getMathElement(j).paint(g, x, posY+y);
        final MathTableData mtd = row.getMathElement(j) as MathTableData;
        if (mtd.getColumnAlign() == "left")
          mtd.paint(context, x + 1, posY + y);
        else if (mtd.getColumnAlign() == "right")
          mtd.paint(context, x + maxcolumnwidth[j] - mtd.getWidth(true), posY + y);
        else
          mtd.paint(context, x + maxcolumnwidth[j] / 2 - mtd.getWidth(true) / 2, posY + y);
        x += maxcolumnwidth[j];
      }

      y += maxrowdescentheight[i];
      if (i < getMathElementCount() - 1)
        y += maxrowascentheight[i + 1];
    }
  }

  /**
   * Returns the maximal ascent height of a row in this table
   *
   * @param row Row     
   *
   * @return Maximal ascent height
   */
  double getMaxRowAscentHeight(final int row) {
    if (row >= getMathElementCount())
      return 0.0;

    final MathElement child = getMathElement(row);
    double height = 0.0;

    for (int i = 0; i < child.getMathElementCount(); i++)
      height = max(height, child.getMathElement(i).getAscentHeight(true));
    return height;
  }

  /**
   * Returns the maximal descent height of a row in this table
   *
   * @param row Row
   *
   * @return Maximal descent height
   */
  double getMaxRowDescentHeight(final int row) {
    if (row >= getMathElementCount())
      return 0.0;

    final MathElement child = getMathElement(row);
    double height = 0.0;

    for (int i = 0; i < child.getMathElementCount(); i++)
      height = max(height, child.getMathElement(i).getDescentHeight(true));
    return height;
  }

  /**
   * Returns the maximal width of a column
   * in this table
   *
   * @param column Column
   *
   * @return Maximal width
   */
  double getMaxColumnWidth(final int column) {
    double width = 0.0;

    for (int i = 0; i < getMathElementCount(); i++)
    {
      final MathElement child = getMathElement(i);

      if (column < child.getMathElementCount())
        width = max(width, child.getMathElement(column).getWidth(true));
    }
    return width + 2;
  }

  /**
   * Returns the maximal count of columns
   *
   * @return Maximal count of columns
   */
  int getMaxColumnCount() {
    int count = 0;

    for (int i = 0; i < getMathElementCount(); i++) {
      final MathElement child = getMathElement(i);

      count = max(count, child.getMathElementCount());
    }
    return count;
  }

  @override
  double getWidth(final bool dynamicParts) {
    double width = 0.0;
    final int maxcolumns = getMaxColumnCount();

    for (int i = 0; i < maxcolumns; i++)
      width += getMaxColumnWidth(i);
    return width;
  }

  @override
  double getHeight(final bool dynamicParts) {
    double height = 0.0;

    for (int i = 0; i < getMathElementCount(); i++)
      height += getMaxRowAscentHeight(i) + getMaxRowDescentHeight(i);
    return height;
  }

  @override
  double getAscentHeight(final bool dynamicParts) {
    return getHeight(true) / 2 + getMiddleShift();
  }

  @override
  double getDescentHeight(final bool dynamicParts) {
    return getHeight(true) / 2 - getMiddleShift();
  }
  
}
