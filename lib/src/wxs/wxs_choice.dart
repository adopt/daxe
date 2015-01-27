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

part of wxs;


class WXSChoice extends WXSExplicitGroup {
  
  WXSChoice(final Element el, final Parent parent, final WXSSchema schema) {
    _parse(el, parent, schema);
  }
  
  // from WithSubElements
  int validate(final List<WXSElement> subElements, final int start, final bool insertion) {
    int nb = 0;
    for (int i=start; i<subElements.length; ) {
      if (nb >= _maxOccurs)
        return(i);
      int pos = i;
      int max_pos = i;
      for (WithSubElements nestedParticle in _nestedParticles) {
        pos = nestedParticle.validate(subElements, i, insertion);
        if (insertion) {
          // elements b,a with content model (a,b)|(b,a) :
          // all particules have to be tried
          if (pos > max_pos)
            max_pos = pos;
        } else {
          if (pos > i)
            break;
        }
      }
      if (insertion)
        pos = max_pos;
      if (pos == i) {
        if (!insertion && nb < _minOccurs)
          return(start);
        return(i);
      }
      i = pos;
      nb++;
    }
    if (!insertion && nb < _minOccurs)
      return(start);
    return(subElements.length);
  }
  
  // from WithSubElements
  bool isOptionnal() {
    if (_nestedParticles.length == 0)
      return(true);
    if (_minOccurs == 0)
      return(true);
    for (WithSubElements nestedParticle in _nestedParticles) {
      if (nestedParticle.isOptionnal())
        return(true);
    }
    return(false);
  }
  
}
