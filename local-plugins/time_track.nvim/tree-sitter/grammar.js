/**
 * @file Time tracking language.
 * @author Tristan M Barrow <tristanmarkbarrow@gmail.com>
 * @license MIT
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check
// grammer
module.exports = grammar({
  name: "time_track",

  rules: {
    source_file: $ => seq(
      $.date,
      repeat($.day),
    ),
    day: $ => seq(
      $.day_identifier,
      "\n",
      repeat($.time_entry),
    ),
    time_entry: $ => seq(
      $.label_group,
      "\n\n",
      repeat($.note_section),
    ),
    note_section: $ => seq(
      $.note_title,
      repeat($.note),
    ),
    note: $ => seq(
      $.list_bullet,
      $.note_content,
      "\n",
    ),
    date: $ => seq(
      $.year,
      '-',
      $.number,
      '-',
      $.number,
    ),
    label_group: $ => seq(
      '|',
      $.identifier,
      ' - ',
      $.number,
      '|',
    ),
    day_identifier: $ => /==(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)==/,
    note_title: $ => /# [A-Z][a-z]+/,
    identifier: $ => /\w+/,
    list_bullet: $ => /-\ /,
    note_content: $ => /[\w\.,\ \(\)\[\]]+/,
    year: $ => /20\d{2}/,
    number: $ => /\d{1,2}/,
  }
});
