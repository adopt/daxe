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

/**
 * Implementation for Jaxe style equations.
 * Syntax documented [here](http://jaxe.sourceforge.net/en/pages_jaxe-user-guide/equations.html).
 */
library equations;

//import 'package:meta/meta.dart';
import 'dart:html' as h;
import 'dart:math';

import '../strings.dart';

part 'equation_dialog.dart';
part 'math_base.dart';
part 'string_math_builder.dart';
part 'text_metrics.dart';

part 'elements/math_element.dart';
part 'elements/math_frac.dart';
part 'elements/math_identifier.dart';
part 'elements/math_number.dart';
part 'elements/math_operator.dart';
part 'elements/math_over.dart';
part 'elements/math_phantom.dart';
part 'elements/math_root.dart';
part 'elements/math_root_element.dart';
part 'elements/math_row.dart';
part 'elements/math_sqrt.dart';
part 'elements/math_sub.dart';
part 'elements/math_sub_sup.dart';
part 'elements/math_sup.dart';
part 'elements/math_table.dart';
part 'elements/math_table_data.dart';
part 'elements/math_table_row.dart';
part 'elements/math_text.dart';
part 'elements/math_under.dart';
part 'elements/math_under_over.dart';

typedef void ActionFunction();


