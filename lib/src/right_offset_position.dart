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
 * A position in the XML document based on the document offset from the end.
 */
class RightOffsetPosition implements Position {
  int _rightOffset;
  
  RightOffsetPosition(int rightOffset) {
    assert(rightOffset >= 0);
    _rightOffset = rightOffset;
  }
  
  RightOffsetPosition.fromNodeOffsetPosition(NodeOffsetPosition nopos) {
    DaxeNode targetDn = nopos.dn;
    int targetDnOffset = nopos.dnOffset;
    _rightOffset = 0;
    DaxeNode dn = doc.dndoc;
    int dnOffset = dn.offsetLength;
    while (dn != targetDn || dnOffset != targetDnOffset) {
      if (dnOffset == 0) {
        dnOffset = dn.parent.offsetOf(dn);
        dn = dn.parent;
      } else if (dn is DNText) {
        dnOffset--;
      } else {
        dn = dn.childAtOffset(dnOffset-1);
        dnOffset = dn.offsetLength;
      }
      _rightOffset++;
    }
  }
  
  RightOffsetPosition.fromLeftOffsetPosition(LeftOffsetPosition lopos) {
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
    _rightOffset = offset - lopos.leftOffset;
  }
  
  RightOffsetPosition.clone(RightOffsetPosition pos) {
    _rightOffset = pos.rightOffset;
  }
  
  DaxeNode get dn {
    NodeOffsetPosition nopos = new NodeOffsetPosition.fromRightOffsetPosition(this);
    return(nopos.dn);
  }
  
  int get dnOffset {
    NodeOffsetPosition nopos = new NodeOffsetPosition.fromRightOffsetPosition(this);
    return(nopos.dnOffset);
  }
  
  int get leftOffset {
    LeftOffsetPosition lopos = new LeftOffsetPosition.fromRightOffsetPosition(this);
    return(lopos.leftOffset);
  }
  
  int get rightOffset {
    return(_rightOffset);
  }
  
  bool operator ==(Position other) {
    return(_rightOffset == other.rightOffset);
  }
  
  bool operator <(Position other) {
    return(_rightOffset > other.rightOffset);
  }
  
  bool operator <=(Position other) {
    return(_rightOffset >= other.rightOffset);
  }
  
  bool operator >(Position other) {
    return(_rightOffset < other.rightOffset);
  }
  
  bool operator >=(Position other) {
    return(_rightOffset <= other.rightOffset);
  }
  
  void move(int offset) {
    _rightOffset -= offset;
  }
  
  void moveInsideTextNodeIfPossible() {
    NodeOffsetPosition nopos = new NodeOffsetPosition.fromRightOffsetPosition(this);
    nopos.moveInsideTextNodeIfPossible();
    _rightOffset = (new RightOffsetPosition.fromNodeOffsetPosition(nopos))._rightOffset;
  }
  
  Point positionOnScreen() {
    NodeOffsetPosition nopos = new NodeOffsetPosition.fromRightOffsetPosition(this);
    return(nopos.positionOnScreen());
  }
  
  String xPath() {
    NodeOffsetPosition nopos = new NodeOffsetPosition.fromRightOffsetPosition(this);
    return(nopos.xPath());
  }
  
  String toString() {
    return("[RightOffsetPosition $_rightOffset]");
  }
  
}