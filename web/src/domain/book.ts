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
