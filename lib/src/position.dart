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

part of daxe;

/**
 * A position in the XML document.
 */
abstract class Position {
  
  factory Position(DaxeNode node, int offset) {
    return(new NodeOffsetPosition(node, offset));
  }
  
  factory Position.fromLeft(int leftOffset) {
    return(new LeftOffsetPosition(leftOffset));
  }
  
  factory Position.fromRight(int rightOffset) {
    return(new RightOffsetPosition(rightOffset));
  }
  
  factory Position.nodeOffsetPosition(Position pos) {
    if (pos is NodeOffsetPosition)
      return(new NodeOffsetPosition.clone(pos));
    else if (pos is LeftOffsetPosition)
      return(new NodeOffsetPosition.fromLeftOffsetPosition(pos));
    else if (pos is RightOffsetPosition)
      return(new NodeOffsetPosition.fromRightOffsetPosition(pos));
  }
  
  factory Position.leftOffsetPosition(Position pos) {
    if (pos is NodeOffsetPosition)
      return(new LeftOffsetPosition.fromNodeOffsetPosition(pos));
    else if (pos is LeftOffsetPosition)
      return(new LeftOffsetPosition.clone(pos));
    else if (pos is RightOffsetPosition)
      return(new LeftOffsetPosition.fromRightOffsetPosition(pos));
  }
  
  factory Position.rightOffsetPosition(Position pos) {
    if (pos is NodeOffsetPosition)
      return(new RightOffsetPosition.fromNodeOffsetPosition(pos));
    else if (pos is LeftOffsetPosition)
      return(new RightOffsetPosition.fromLeftOffsetPosition(pos));
    else if (pos is RightOffsetPosition)
      return(new RightOffsetPosition.clone(pos));
  }
  
  factory Position.clone(Position pos) {
    if (pos is NodeOffsetPosition)
      return(new NodeOffsetPosition(pos.dn, pos.dnOffset));
    else if (pos is LeftOffsetPosition)
      return(new LeftOffsetPosition(pos.leftOffset));
    else if (pos is RightOffsetPosition)
      return(new RightOffsetPosition(pos.rightOffset));
  }
  
  /**
   * Returns the parent node for this position.
   */
  DaxeNode get dn;
  
  /**
   * Returns the offset within the parent node.
   */
  int get dnOffset;
  
  /**
   * Returns the left offset in the document.
   */
  int get leftOffset;
  
  /**
   * Returns the right offset in the document.
   */
  int get rightOffset;
  
  bool operator ==(Position other);
  
  bool operator <(Position other);
  
  bool operator <=(Position other);
  
  bool operator >(Position other);
  
  bool operator >=(Position other);
  
  /**
   * Moves the position right by the offset, counting movements to enter or exit a text node.
   */
  void move(int offset);
  
  void moveInsideTextNodeIfPossible();
  
  /**
   * offset top-left coordinates for the position
   */
  Point positionOnScreen();
  
  String xPath({bool titles:false});
  
  String toString();
}

/**
 * A point defined by x,y coordinates.
 * The coordinates can be integers or doubles.
 */
class Point {
  num x, y;
  Point(num this.x, num this.y);
}
