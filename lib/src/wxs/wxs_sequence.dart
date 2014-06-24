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



class WXSSequence extends WXSExplicitGroup {
  
  WXSSequence(final Element el, final Parent parent, final WXSSchema schema) {
    _parse(el, parent, schema);
  }
  
  
  // from WithSubElements
  int validate(final List<WXSElement> subElements, final int start, final bool insertion) {
    int nb = 0;
    for (int i=start; i<subElements.length; ) {
      if (nb >= _maxOccurs)
        return(i);
      int pos = i;
      for (WithSubElements nestedParticle in _nestedParticles) {
        int pos2 = nestedParticle.validate(subElements, pos, insertion);
        if (pos2 == pos) {
          if (!insertion && !nestedParticle.isOptionnal()) {
            if (nb < _minOccurs)
              return(start);
            return(i);
          }
        }
        pos = pos2;
      }
      if (pos == i)
        return(i);
      i = pos;
      nb++;
    }
    if (!insertion && nb < _minOccurs)
      return(start);
    return(subElements.length);
  }
  
  // from WithSubElements
  bool isOptionnal() {
    if (_minOccurs == 0)
      return(true);
    for (WithSubElements nestedParticle in _nestedParticles) {
      if (!nestedParticle.isOptionnal())
        return(false);
    }
    return(true);
  }
  
}
