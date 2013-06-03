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
 * A position in the XML document, created with a parent node and offset within this node.
 */
class Position {
  DaxeNode _dn;
  int _dnOffset; // offset within _dn (a child counts for 1 offset)
  // for text nodes, _dnOffset is the offset within the string
  
  Position(DaxeNode node, int offset) {
    assert(node != null);
    assert(offset >= 0);
    _dn = node;
    _dnOffset = offset;
  }
  
  Position.fromHTML(h.Node offsetNode, int offsetValue) {
    _dnOffset = offsetValue;
    if (offsetNode.nodeType == DaxeNode.TEXT_NODE) {
      _dn = doc.getNodeById(offsetNode.parent.attributes['id']);
    } else {
      h.Element el = offsetNode as h.Element;
      _dn = doc.getNodeById(el.attributes['id']);
      //todo: fix _dnOffset
    }
    assert(_dn != null);
    assert(_dn.nodeType == DaxeNode.TEXT_NODE);
  }
  
  Position.clone(Position pos) {
    _dn = pos.dn;
    _dnOffset = pos.dnOffset;
  }
  
  /**
   * Returns the parent node for this position.
   */
  DaxeNode get daxeNode {
    return(_dn);
  }
  
  /**
   * Returns the parent node for this position.
   */
  DaxeNode get dn {
    return(_dn);
  }
  
  h.Element get htmlNode {
    return(_dn.getHTMLNode());
  }
  
  int get htmlOffset {
    // todo: fix for !next
    String v = _dn.nodeValue;
    int offset = _dnOffset;
    return(offset);
  }
  
  /**
   * Returns the offset within the parent node.
   */
  int get dnOffset {
    return(_dnOffset);
  }
  
  bool operator ==(Position other) {
    return(_dn == other.dn && _dnOffset == other.dnOffset);
  }
  
  bool operator <(Position other) {
    DaxeNode cp = null;
    DaxeNode p1 = _dn;
    double offset1 = _dnOffset.toDouble();
    while (p1 != null) {
      DaxeNode p2 = other.dn;
      double offset2 = other.dnOffset.toDouble();
      while (p2 != null) {
        if (p1 == p2) {
          return(offset1 < offset2);
        }
        if (p2.parent == null)
          break;
        offset2 = p2.parent.offsetOf(p2) + 0.5;
        p2 = p2.parent;
      }
      if (p1.parent == null)
        break;
      offset1 = p1.parent.offsetOf(p1) + 0.5;
      p1 = p1.parent;
    }
    assert(false); // no common parent ???
  }
  
  bool operator <=(Position other) {
    return(this < other || this == other);
  }
  
  bool operator >(Position other) {
    return(!(this == other || this < other));
  }
  
  bool operator >=(Position other) {
    return(this > other || this == other);
  }
  
  void move(int offset) {
    moveInsideTextNodeIfPossible();
    if (offset < 0 && _dnOffset + offset >= 0 && _dn.nodeType != DaxeNode.TEXT_NODE &&
        _dn.nodeType != DaxeNode.COMMENT_NODE) {
      Position pos = _dn.childNodes[_dnOffset - 1].lastCursorPositionInside();
      if (pos != null) {
        _dn = pos.dn;
        _dnOffset = pos.dnOffset;
      } else {
        _dnOffset = _dnOffset - 1;
      }
    } else if (_dnOffset + offset < 0) {
      DaxeNode prev = _dn.previousSibling;
      if (prev != null && _dn.nodeType == DaxeNode.TEXT_NODE) {
        Position pos = prev.lastCursorPositionInside();
        if (pos != null) {
          _dn = pos.dn;
          _dnOffset = pos.dnOffset;
        } else {
          _dn = prev.parent;
          _dnOffset = prev.parent.offsetOf(prev);
        }
      } else {
        if (_dn.parent == null)
          return;
        if (_dn.nodeType == DaxeNode.TEXT_NODE && _dn.parent.parent != null) {
          if (_dn.parent.previousSibling != null && _dn.parent.previousSibling.nodeType == DaxeNode.TEXT_NODE) {
            _dnOffset = _dn.parent.previousSibling.offsetLength;
            _dn = _dn.parent.previousSibling;
          } else {
            _dnOffset = _dn.parent.parent.offsetOf(_dn.parent);
            _dn = _dn.parent.parent;
          }
        } else {
          _dnOffset = _dn.parent.offsetOf(_dn);
          _dn = _dn.parent;
        }
      }
    } else if (_dn.nodeValue == null || _dnOffset + offset > _dn.nodeValue.length) {
      if ((_dn.nodeType == DaxeNode.ELEMENT_NODE || _dn.nodeType == DaxeNode.DOCUMENT_NODE) &&
          _dn.offsetLength > _dnOffset) {
        Position pos = dn.childNodes[_dnOffset].firstCursorPositionInside();
        if (pos != null) {
          _dn = pos.dn;
          _dnOffset = pos.dnOffset;
        } else {
          _dnOffset = _dnOffset + 1;
        }
      } else {
        DaxeNode next = _dn.nextSibling;
        if (next != null && _dn.nodeType == DaxeNode.TEXT_NODE) {
          Position pos = next.firstCursorPositionInside();
          if (pos != null) {
            _dn = pos.dn;
            _dnOffset = pos.dnOffset;
          } else {
            _dn = next.parent;
            _dnOffset = next.parent.offsetOf(next) + 1;
          }
        } else if (_dn.parent != null) {
          if (_dn.nodeType == DaxeNode.TEXT_NODE && _dn.parent.parent != null) {
            _dnOffset = _dn.parent.parent.offsetOf(_dn.parent) + 1;
            _dn = _dn.parent.parent;
          } else {
            _dnOffset = _dn.parent.offsetOf(_dn) + 1;
            _dn = _dn.parent;
          }
        }
      }
    } else {
      _dnOffset += offset;
    }
    moveInsideTextNodeIfPossible();
  }
  
  void moveInsideTextNodeIfPossible() {
    if (_dn.nodeType == DaxeNode.ELEMENT_NODE && _dnOffset > 0 &&
        _dn.childNodes[_dnOffset - 1].nodeType == DaxeNode.TEXT_NODE) {
      _dn = _dn.childNodes[_dnOffset - 1];
      _dnOffset = _dn.offsetLength;
    } else if (_dn.nodeType == DaxeNode.ELEMENT_NODE &&
        _dnOffset < _dn.offsetLength &&
        _dn.childAtOffset(_dnOffset).nodeType == DaxeNode.TEXT_NODE) {
      _dn = _dn.childAtOffset(_dnOffset);
      _dnOffset = 0;
    } else if (_dnOffset == 0 && _dn.firstChild != null &&
        _dn.firstChild.nodeType == DaxeNode.TEXT_NODE) {
      _dn = _dn.firstChild;
    }
  }
  
  /**
   * offset top-left coordinates for the position
   */
  Point positionOnScreen() {
    if (_dn.nodeType == DaxeNode.TEXT_NODE || _dn.nodeType == DaxeNode.COMMENT_NODE) {
      h.Element hn = _dn.getHTMLContentsNode();
      if (hn == null || hn.nodes.length == 0)
        return(null);
      h.Text n = hn.nodes.first;
      int offset = htmlOffset;
      String s = n.text; // Dart bug here sometimes (type int/String ?!?)
      assert(s.length != 0);
      /*
      h.Text n2 = new h.Text(s.substring(offset));
      if (s.length == offset)
        n2.text = "|";
      n.text = s.substring(0, offset);
      h.SpanElement spos = new h.SpanElement();
      spos.append(n2);
      if (n.nextNode == null)
        n.parent.append(spos);
      else
        n.parent.insertBefore(spos, n.nextNode);
      h.Rect r = spos.getClientRects()[0];
      Point pt = new Point(r.left, r.top);
      spos.remove();
      */
      // changing the text might induce
      // layout changes which move the position (for instance in a table cell)
      // -> we add a span on the text after the cursor
      /*
      Point pt;
      if (offset != 0) {
        n.text = s.substring(0, offset);
        h.SpanElement spos = new h.SpanElement();
        spos.appendText(s.substring(offset));
        if (n.nextNode == null)
          n.parent.append(spos);
        else
          n.parent.insertBefore(spos, n.nextNode);
        h.Rect r = spos.getClientRects()[0];
        pt = new Point(r.left, r.top);
        spos.remove();
        n.text = s;
      } else {
        h.Rect r = n.parent.getClientRects()[0];
        pt = new Point(r.left, r.top);
      }
      // new problem: wrong position when the cursor is before an hyphen inside
      // a broken word at the end of the line
      */
      // trying with Range...
      // this does not work in the case of an element following a line breaking space
      h.Range range = new h.Range();
      Point pt;
      if (offset == 0) {
        range.setStart(n, offset);
        range.setEnd(n, s.length);
        h.Rect r = range.getClientRects().first;
        pt = new Point(r.left, r.top);
      } else if (s[offset-1] == '\n' || s[offset-1] == ' ') {
        // to the right of a \n or a space
        if (offset == s.length) {
          // ranges always report wrong positions in this case :(
          if (_dn.nextSibling != null && _dn.nextSibling.nodeType == DaxeNode.ELEMENT_NODE) {
            h.Rect r = (_dn.nextSibling.getHTMLNode()).getClientRects()[0];
            pt = new Point(r.left, r.top);
          } else if (s[offset-1] == ' ') {
            range.setStart(n, 0);
            range.setEnd(n, offset);
            h.Rect r = range.getClientRects().last;
            pt = new Point(r.right, r.top);
          } else {
            h.SpanElement spos = new h.SpanElement();
            spos.appendText("|");
            if (n.nextNode == null)
              hn.append(spos);
            else
              hn.insertBefore(spos, n.nextNode);
            h.Rect r = spos.getClientRects()[0];
            pt = new Point(r.left, r.top);
            spos.remove();
          }
        } else {
          range.setStart(n, offset);
          range.setEnd(n, offset + 1);
          List<h.Rect> rects = range.getClientRects();
          h.Rect r;
          if (s[offset-1] == ' ' && s[offset] == '\n')
            r = rects.first;
          else if (s[offset] == '\n' && rects.length == 3)
            r = rects[1];
          else
            r = rects.last;
          pt = new Point(r.left, r.top);
        }
      } else {
        range.setStart(n, 0);
        range.setEnd(n, offset);
        h.Rect r = range.getClientRects().last;
        pt = new Point(r.right, r.top);
      }
      return(pt);
      
    } else { // not in a text node:
      List<DaxeNode> children = _dn.childNodes;
      if (children != null && _dnOffset > 0 && _dnOffset == children.length) {
        // at the end of the children
        h.Node n = children[_dnOffset-1].getHTMLNode();
        h.Rect r;
        if (n is h.ImageElement || n is h.TableRowElement) {
          r = n.getBoundingClientRect();
          return(new Point(r.right, r.top));
        } else if (n is h.DivElement || n is h.TableElement || n is h.UListElement) {
          r = n.getBoundingClientRect();
          return(new Point(r.left, r.bottom));
        } else {
          if (n == null)
            return(null);
          h.SpanElement spos = new h.SpanElement();
          spos.append(new h.Text("|"));
          n.append(spos);
          List<h.Rect> rects = spos.getClientRects();
          if (rects.length > 0)
            r = rects[0];
          else
            r = null;
          spos.remove();
          if (r == null)
            return(null);
          return(new Point(r.left, r.top));
        }
      } else if (children != null && _dnOffset < children.length) {
        // within the children
        DaxeNode n = children[_dnOffset];
        h.Element hn = n.getHTMLNode();
        if (hn == null)
          return(null);
        h.Rect r = hn.getClientRects()[0];
        Point pt = new Point(r.left, r.top);
        return(pt);
      } else {
        // no child inside _dn
        assert(_dnOffset == 0);
        h.Element hn = _dn.getHTMLContentsNode();
        h.Rect r = hn.getClientRects()[0];
        Point pt = new Point(r.left, r.top);
        return(pt);
      }
    }
  }
  
  String xPath() {
    String s = "";
    DaxeNode n = _dn;
    while (n != null) {
      String spos = "";
      if (n.parent != null) {
        int position = 1;
        for (DaxeNode n2 = n.parent.firstChild; n2 != null; n2 = n2.nextSibling) {
          if (n2 == n)
            break;
          if (n2.nodeType == DaxeNode.ELEMENT_NODE && n2.nodeName == n.nodeName)
            position++;
        }
        spos = "[$position]";
      }
      if (n.nodeType == DaxeNode.ELEMENT_NODE)
        s = "${n.nodeName}$spos/$s";
      else if (n.nodeType == DaxeNode.TEXT_NODE)
        s = "#text";
      n = n.parent;
    }
    return("/$s");
  }
  
  String toString() {
    return("[Position ${_dn.nodeName} ${_dnOffset}]");
  }
}

class Point {
  num x, y;
  Point(num this.x, num this.y);
}
