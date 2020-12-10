import { Book } from "./book";

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
