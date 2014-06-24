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
 * XML DOM API based on the [W3C recommandation](http://www.w3.org/TR/DOM-Level-3-Core/core.html)
 * but not all features are implemented.
 * A document can be parsed with [DOMParser].
 */
library xmldom;

import 'dart:async';
import 'dart:collection';
import 'dart:html' as h;
import 'dart:math';

part 'attr.dart';
part 'cdata_section.dart';
part 'comment.dart';
part 'document.dart';
part 'document_fragment.dart';
part 'document_type.dart';
part 'dom_implementation.dart';
part 'element.dart';
part 'entity_reference.dart';
part 'node.dart';
part 'processing_instruction.dart';
part 'text.dart';

part 'attr_impl.dart';
part 'cdata_section_impl.dart';
part 'comment_impl.dart';
part 'document_impl.dart';
part 'document_fragment_impl.dart';
part 'document_type_impl.dart';
part 'dom_implementation_impl.dart';
part 'element_impl.dart';
part 'entity_reference_impl.dart';
part 'node_impl.dart';
part 'processing_instruction_impl.dart';
part 'text_impl.dart';

part 'dom_exception.dart';
part 'dom_parser.dart';

part 'parser/engine.dart';
part 'parser/match_result.dart';
part 'parser/state_change.dart';
part 'parser/state_condition.dart';
part 'parser/token.dart';
part 'parser/token_char.dart';
part 'parser/token_sequence.dart';
part 'parser/token_id.dart';
part 'parser/token_item.dart';
part 'parser/token_choice.dart';
part 'parser/token_repeat.dart';
part 'parser/token_rule.dart';
part 'parser/xml_parser.dart';
