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
class NodeOffsetPosition implements Position {
  DaxeNode _dn;
  int _dnOffset; // offset within _dn (a child counts for 1 offset)
  // for text nodes, _dnOffset is the offset within the string
  
  NodeOffsetPosition(DaxeNode node, int offset) {
    assert(node != null);
    assert(offset >= 0);
    _dn = node;
    _dnOffset = offset;
  }
  
  NodeOffsetPosition.fromLeftOffsetPosition(LeftOffsetPosition lopos) {
    _dn = doc.dndoc;
    _dnOffset = 0;
    move(lopos.leftOffset);
  }
  
  NodeOffsetPosition.fromRightOffsetPosition(RightOffsetPosition ropos) {
    _dn = doc.dndoc;
    _dnOffset = _dn.offsetLength;
    move(-ropos.rightOffset);
  }
  
  NodeOffsetPosition.clone(Position pos) {
    _dn = pos.dn;
    _dnOffset = pos.dnOffset;
  }
  
  DaxeNode get dn {
    return(_dn);
  }
  
  int get dnOffset {
    return(_dnOffset);
  }
  
  int get leftOffset {
    LeftOffsetPosition lopos = new LeftOffsetPosition.fromNodeOffsetPosition(this);
    return(lopos.leftOffset);
  }
  
  int get rightOffset {
    RightOffsetPosition ropos = new RightOffsetPosition.fromNodeOffsetPosition(this);
    return(ropos.rightOffset);
  }
  
  bool operator ==(Position other) {
    NodeOffsetPosition nopos;
    if (other is NodeOffsetPosition)
      nopos = other;
    else if (other is LeftOffsetPosition)
      nopos = new NodeOffsetPosition.fromLeftOffsetPosition(other);
    else if (other is RightOffsetPosition)
      nopos = new NodeOffsetPosition.fromRightOffsetPosition(other);
    return(_dn == nopos._dn && _dnOffset == nopos._dnOffset);
  }
  
  bool operator <(Position other) {
    NodeOffsetPosition nopos;
    if (other is NodeOffsetPosition)
      nopos = other;
    else if (other is LeftOffsetPosition)
      nopos = new NodeOffsetPosition.fromLeftOffsetPosition(other);
    else if (other is RightOffsetPosition)
      nopos = new NodeOffsetPosition.fromRightOffsetPosition(other);
    DaxeNode cp = null;
    DaxeNode p1 = _dn;
    double offset1 = _dnOffset.toDouble();
    while (p1 != null) {
      DaxeNode p2 = nopos._dn;
      double offset2 = nopos._dnOffset.toDouble();
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
    return(false);
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
    if (offset > 0) {
      int n = offset;
      while (n > 0) {
        if (_dnOffset == _dn.offsetLength) {
          _dnOffset = _dn.parent.offsetOf(_dn) + 1;
          _dn = _dn.parent;
        } else if (_dn is DNText) {
          _dnOffset++;
        } else {
          _dn = _dn.childAtOffset(_dnOffset);
          _dnOffset = 0;
        }
        n--;
      }
    } else if (offset < 0) {
      int n = offset;
      while (n < 0) {
        if (_dnOffset == 0) {
          _dnOffset = _dn.parent.offsetOf(_dn);
          _dn = _dn.parent;
        } else if (_dn is DNText) {
          _dnOffset--;
        } else {
          _dn = _dn.childAtOffset(_dnOffset-1);
          _dnOffset = _dn.offsetLength;
        }
        n++;
      }
    }
  }
  
  void moveInsideTextNodeIfPossible() {
    if (_dn.nodeType == DaxeNode.ELEMENT_NODE && _dnOffset > 0 &&
        _dn.childAtOffset(_dnOffset - 1).nodeType == DaxeNode.TEXT_NODE) {
      _dn = _dn.childAtOffset(_dnOffset - 1);
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
    if (_dn.nodeType == DaxeNode.TEXT_NODE) {
      h.Element hn = _dn.getHTMLContentsNode();
      if (hn == null || hn.nodes.length == 0)
        return(null);
      assert(hn.nodes.first is h.Text);
      h.Text n = hn.nodes.first;
      int offset = _dnOffset; // TODO:fix for !next
      String s = n.text;
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
        h.Rectangle r = range.getClientRects().first;
        pt = new Point(r.left, r.top);
      } else if (s[offset-1] == '\n' || s[offset-1] == ' ') {
        // to the right of a \n or a space
        if (offset == s.length) {
          // ranges always report wrong positions in this case :(
          if (_dn.nextSibling != null && _dn.nextSibling.nodeType == DaxeNode.ELEMENT_NODE &&
              (s[offset-1] == '\n' || !_dn.nextSibling.block)) {
            h.Rectangle r = (_dn.nextSibling.getHTMLNode()).getClientRects()[0];
            pt = new Point(r.left, r.top);
          } else if (s[offset-1] == ' ') {
            range.setStart(n, 0);
            range.setEnd(n, offset);
            h.Rectangle r = range.getClientRects().last;
            pt = new Point(r.right, r.top);
          } else {
            // FIXME: adding a span with text can change a table layout with Firefox, causing wrong results
            h.SpanElement spos = new h.SpanElement();
            spos.appendText("|");
            if (n.nextNode == null)
              hn.append(spos);
            else
              hn.insertBefore(spos, n.nextNode);
            h.Rectangle r = spos.getClientRects()[0];
            pt = new Point(r.left, r.top);
            spos.remove();
          }
        } else {
          range.setStart(n, offset);
          range.setEnd(n, offset + 1);
          List<h.Rectangle> rects = range.getClientRects();
          h.Rectangle r;
          if (s[offset-1] == ' ' && s[offset] == '\n')
            r = rects.first;
          else if (s[offset] == '\n' && rects.length == 3)
            r = rects[1];
          else if (h.window.navigator.userAgent.toLowerCase().indexOf('msie') >= 0 &&
              s[offset-1] == '\n' && s[offset] == '\n' && rects.length == 2) // IE
            r = rects.first;
          else {
            // preferably use a Rectangle with a width > 1 (useful in the case of 1\n2\n with Chromium)
            r = rects.last;
            for (h.Rectangle ri in rects)
              if (ri.width > 1) {
                r = ri;
                break;
              }
          }
          pt = new Point(r.left, r.top);
        }
      } else {
        range.setStart(n, 0);
        range.setEnd(n, offset);
        h.Rectangle r = range.getClientRects().last;
        pt = new Point(r.right, r.top);
      }
      return(pt);
      
    } else { // not in a text node:
      List<DaxeNode> children = _dn.childNodes;
      if (children != null && _dnOffset > 0 && _dnOffset == children.length) {
        // at the end of the children
        h.Element n = children[_dnOffset-1].getHTMLNode();
        if (n == null)
          return(null);
        h.Rectangle r;
        if (n is h.ImageElement || n is h.TableRowElement) {
          r = n.getBoundingClientRect();
          return(new Point(r.right, r.top));
        } else if (n is h.DivElement || n is h.TableElement || n is h.UListElement || n is h.LIElement) {
          r = n.getBoundingClientRect();
          return(new Point(r.left, r.bottom));
        } else {
          /*
          // FIXME: adding a span with text can change a table layout with Firefox, causing wrong results
          h.SpanElement spos = new h.SpanElement();
          spos.append(new h.Text("|"));
          n.append(spos);
          List<h.Rectangle> rects = spos.getClientRects();
          if (rects.length > 0)
            r = rects[0];
          else
            r = null;
          spos.remove();
          if (r == null)
            return(null);
          return(new Point(r.left, r.top));
          */
          // this seems to work (top right corner of the last rect of the last child's HTML):
          List<h.Rectangle> rects = n.getClientRects();
          if (rects.length == 0)
            return(null);
          h.Rectangle r = rects.last;
          return(new Point(r.right, r.top));
        }
      } else if (children != null && _dnOffset < children.length) {
        // within the children
        h.Element hn = children[_dnOffset].getHTMLNode();
        if (hn == null)
          return(null);
        if (_dnOffset > 0) {
          // between two nodes
          DaxeNode dn1 = children[_dnOffset - 1];
          DaxeNode dn2 = children[_dnOffset];
          h.Element hn1 = dn1.getHTMLNode();
          h.Element hn2 = hn;
          if (dn1.block && !dn2.block) {
            // block-inline
            List<h.Rectangle> rects2 = hn2.getClientRects();
            if (rects2.length == 0 )
              return(null);
            h.Rectangle r2 = rects2.first;
            return(new Point(r2.left, r2.top));
          } else if (dn1.block && dn2.block) {
            // block-block
            h.Rectangle r1 = hn1.getBoundingClientRect();
            h.Rectangle r2 = hn2.getBoundingClientRect();
            return(new Point(r2.left, (r1.bottom + r2.top)/2));
          } else {
            // inline-inline or inline-block
            List<h.Rectangle> rects1 = hn1.getClientRects();
            if (rects1.length == 0 )
              return(null);
            h.Rectangle r1 = rects1.last;
            return(new Point(r1.right, r1.top));
          }
        }
        // before the first node
        if (children[_dnOffset] is DNWItem) {
          // special case for the first li in a WYSIWYG list
          h.Rectangle r = hn.getClientRects()[0];
          return(new Point(r.left - 21, r.top + 2));
        }
        h.Rectangle r = hn.getClientRects()[0];
        return(new Point(r.left, r.top));
      } else {
        // no child inside _dn
        assert(_dnOffset == 0);
        h.Element hn = _dn.getHTMLContentsNode();
        if (hn == null)
          return(null);
        List<h.Rectangle> rects = hn.getClientRects();
        if (rects.length == 0)
          return(null);
        h.Rectangle r = rects[0];
        return(new Point(r.left, r.top));
      }
    }
  }
  
  String xPath({bool titles:false}) {
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
      if (n.nodeType == DaxeNode.ELEMENT_NODE) {
        String title;
        if (titles && doc.cfg != null && n.ref != null)
          title = doc.cfg.elementTitle(n.ref);
        else
          title = n.nodeName;
        s = "$title$spos/$s";
      } else if (n.nodeType == DaxeNode.TEXT_NODE)
        s = "#text";
      n = n.parent;
    }
    return("/$s");
  }
  
  String toString() {
    return("[NodeOffsetPosition ${_dn.nodeName} ${_dnOffset}]");
  }
}
