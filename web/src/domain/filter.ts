import { Book } from "./book";

export class Filter {
  readonly name: string;
  readonly filter: (book: Book) => boolean;

  constructor(name: string, filter: (book: Book) => boolean) {
    this.name = name;
    this.filter = filter;
  }
}
