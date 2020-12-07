export class Book {
  readonly id: string;
  readonly name: string;
  readonly pageCount: number;

  constructor(id: string, name: string, pageCount: number) {
    this.id = id;
    this.name = name;
    this.pageCount = pageCount;
  }
}
