// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import { Book } from "./book";

export class Collection {
  readonly id: string;
  readonly name: string;
  readonly books: Book[];

  constructor(id: string, name: string, books: Book[]) {
    this.id = id;
    this.name = name;
    this.books = books;
  }
}
