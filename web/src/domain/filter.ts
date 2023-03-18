// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import { Book } from "./book.ts";

export class Filter {
  readonly id: string;
  readonly name: string;
  readonly filter: (book: Book) => boolean;

  constructor(id: string, name: string, filter: (book: Book) => boolean) {
    this.id = id;
    this.name = name;
    this.filter = filter;
  }
}
