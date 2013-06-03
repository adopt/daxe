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

part of nodes;

/**
 * Style node (changes the style without showing tags).
 * Jaxe display type: 'style'
 * parameter: style: GRAS | ITALIQUE | EXPOSANT | INDICE | SOULIGNE | BARRE |
 *                   PCOULEUR[###,###,###] | FCOULEUR[###,###,###]
 *            (several styles can be combined with a ';')
 */
class DNStyle extends DaxeNode {
  
  String _style;
  
  DNStyle.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
    _style = doc.cfg.elementParameterValue(elementRef, 'style', null);
  }
  
  DNStyle.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent) {
    _style = doc.cfg.elementParameterValue(ref, 'style', null);
  }
  
  @override
  h.Element html() {
    h.Element span = new h.SpanElement();
    span.id = "$id";
    span.classes.add('dn');
    if (firstChild != null) { // TODO: test for empty sub-styles
      h.SpanElement contents = new h.SpanElement();
      DaxeNode dn = firstChild;
      while (dn != null) {
        contents.append(dn.html());
        dn = dn.nextSibling;
      }
      setStyle(contents);
      span.append(contents);
    } else {
      // let's make this invisible style visible !
      Tag b1 = new Tag(this, Tag.START);
      Tag b2 = new Tag(this, Tag.END);
      span.append(b1.html());
      h.SpanElement contents = new h.SpanElement();
      span.append(contents);
      span.append(b2.html());
    }
    return(span);
  }
  
  @override
  void updateHTMLAfterChildrenChange(List<DaxeNode> changed) {
    super.updateHTML();
  }
  
  @override
  h.Element getHTMLContentsNode() {
    if (firstChild != null)
      return(getHTMLNode().nodes.first);
    else
      return(getHTMLNode().nodes[1]);
  }
}
