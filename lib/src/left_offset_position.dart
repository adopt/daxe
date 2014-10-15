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
 * A position in the XML document based on the document offset from the start.
 */
class LeftOffsetPosition implements Position {
  int _leftOffset;
  
  LeftOffsetPosition(int leftOffset) {
    assert(leftOffset >= 0);
    _leftOffset = leftOffset;
  }
  
  LeftOffsetPosition.fromNodeOffsetPosition(NodeOffsetPosition nopos) {
    DaxeNode targetDn = nopos.dn;
    int targetDnOffset = nopos.dnOffset;
    _leftOffset = 0;
    DaxeNode dn = doc.dndoc;
    int dnOffset = 0;
    while (dn != targetDn || dnOffset != targetDnOffset) {
      if (dnOffset == dn.offsetLength) {
        dnOffset = dn.parent.offsetOf(dn) + 1;
        dn = dn.parent;
      } else if (dn is DNText) {
        dnOffset++;
      } else {
        dn = dn.childAtOffset(dnOffset);
        dnOffset = 0;
      }
      _leftOffset++;
    }
  }
  
  LeftOffsetPosition.fromRightOffsetPosition(RightOffsetPosition ropos) {
    DaxeNode targetDn = doc.dndoc;
    int targetDnOffset = targetDn.offsetLength;
    int offset = 0;
    DaxeNode dn = doc.dndoc;
    int dnOffset = 0;
    while (dn != targetDn || dnOffset != targetDnOffset) {
      if (dnOffset == dn.offsetLength) {
        dnOffset = dn.parent.offsetOf(dn) + 1;
        dn = dn.parent;
      } else if (dn is DNText) {
        dnOffset++;
      } else {
        dn = dn.childAtOffset(dnOffset);
        dnOffset = 0;
      }
      offset++;
    }
    _leftOffset = offset - ropos.rightOffset;
  }
  
  LeftOffsetPosition.clone(LeftOffsetPosition pos) {
    _leftOffset = pos.leftOffset;
  }
  
  DaxeNode get dn {
    NodeOffsetPosition nopos = new NodeOffsetPosition.fromLeftOffsetPosition(this);
    return(nopos.dn);
  }
  
  int get dnOffset {
    NodeOffsetPosition nopos = new NodeOffsetPosition.fromLeftOffsetPosition(this);
    return(nopos.dnOffset);
  }
  
  int get leftOffset {
    return(_leftOffset);
  }
  
  int get rightOffset {
    RightOffsetPosition ropos = new RightOffsetPosition.fromLeftOffsetPosition(this);
    return(ropos.rightOffset);
  }
  
  bool operator ==(Position other) {
    return(_leftOffset == other.leftOffset);
  }
  
  bool operator <(Position other) {
    return(_leftOffset < other.leftOffset);
  }
  
  bool operator <=(Position other) {
    return(_leftOffset <= other.leftOffset);
  }
  
  bool operator >(Position other) {
    return(_leftOffset > other.leftOffset);
  }
  
  bool operator >=(Position other) {
    return(_leftOffset >= other.leftOffset);
  }
  
  void move(int offset) {
    _leftOffset += offset;
  }
  
  void moveInsideTextNodeIfPossible() {
    NodeOffsetPosition nopos = new NodeOffsetPosition.fromLeftOffsetPosition(this);
    nopos.moveInsideTextNodeIfPossible();
    _leftOffset = nopos.leftOffset;
  }
  
  Point positionOnScreen() {
    NodeOffsetPosition nopos = new NodeOffsetPosition.fromLeftOffsetPosition(this);
    return(nopos.positionOnScreen());
  }
  
  String xPath({bool titles:false}) {
    NodeOffsetPosition nopos = new NodeOffsetPosition.fromLeftOffsetPosition(this);
    return(nopos.xPath(titles:titles));
  }
  
  String toString() {
    return("[LeftOffsetPosition $_leftOffset]");
  }
  
}