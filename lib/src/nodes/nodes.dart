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
 * Core Daxe nodes. Other Daxe nodes should be added into other libraries and defined as plugins in the config file.
 */

library nodes;

import 'dart:async';
import 'dart:collection';
import 'dart:html' as h;
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
//import 'package:meta/meta.dart';

import '../xmldom/xmldom.dart' as x;
import '../equations/equations.dart' show EquationDialog, MathBase, StringMathBuilder;
import '../strings.dart' show Strings;
import '../../daxe.dart' show doc, page, ActionFunction, DaxeAttr, DaxeNode, DaxeException, HelpDialog,
  NodeFactory, Position, Tag, UndoableEdit;

part 'dn_anchor.dart';
part 'dn_area.dart';
part 'dn_cdata.dart';
part 'dn_comment.dart';
part 'dn_division.dart';
part 'dn_equa_tex_mem.dart';
part 'dn_document.dart';
part 'dn_empty.dart';
part 'dn_equation_mem.dart';
part 'dn_file.dart';
part 'dn_form.dart';
part 'dn_form_field.dart';
part 'dn_hidden_div.dart';
part 'dn_hidden_p.dart';
part 'dn_hr.dart';
part 'dn_item.dart';
part 'dn_line_break.dart';
part 'dn_list.dart';
part 'parent_updating_dn_text.dart';
part 'dn_processing_instruction.dart';
part 'dn_simple_type.dart';
part 'dn_special.dart';
part 'dn_string.dart';
part 'dn_style.dart';
part 'dn_style_span.dart';
part 'dn_table.dart';
part 'dn_text.dart';
part 'dn_wlist.dart';
part 'dn_witem.dart';
part 'simple_type_control.dart';
