// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

export class Book {
  readonly id: string;
  readonly name: string;
  readonly pageCount: number;
  readonly readCount: number;

  constructor(id: string, name: string, pageCount: number, readCount: number) {
    this.id = id;
    this.name = name;
    this.pageCount = pageCount;
    this.readCount = readCount;
  }
}
