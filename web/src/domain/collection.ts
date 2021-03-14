// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import { Book } from "./book";

export class Collection {
  readonly id: string;
  readonly name: string;
  readonly bookIds: string[];

  constructor(id: string, name: string, books: Book[]) {
    this.id = id;
    this.name = name;
    this.bookIds = books.map((book) => book.id);
  }
}
