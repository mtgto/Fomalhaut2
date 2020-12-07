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
