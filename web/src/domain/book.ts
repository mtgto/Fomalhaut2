// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

export class Book {
  readonly id: string;
  readonly name: string;
  readonly pageCount: number;
  readonly readCount: number;
  readonly like: boolean;
  readonly isRightToLeft: boolean;
  readonly createdAt: Date;

  constructor(
    id: string,
    name: string,
    pageCount: number,
    readCount: number,
    like: boolean,
    isRightToLeft: boolean,
    createdAt: Date
  ) {
    this.id = id;
    this.name = name;
    this.pageCount = pageCount;
    this.readCount = readCount;
    this.like = like;
    this.isRightToLeft = isRightToLeft;
    this.createdAt = createdAt;
  }
}
