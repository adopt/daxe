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

class Locale {
  
  String language;
  String country;
  
  Locale() {
    //Intl intl = new Intl();
    //List<String> l = intl.locale.split('_')[0];
    language = 'fr';
    country = 'FR';
  }
  
  Locale.l(String language) {
    this.language = language;
    this.country = null;
  }
  
  Locale.lc(String language, String country) {
    this.language = language;
    this.country = country;
  }
  
  bool operator ==(Locale other) {
    return(language == other.language && country == other.country);
  }
  
}

