import React from "react";
import { useParams } from "react-router-dom";

import { Book } from "../domain/book";
import { Collection } from "../domain/collection";
import { Filter } from "../domain/filter";
import Library from "./Library";

type Props = {
  books: Book[];
  collections: Collection[];
  filters: Filter[];
};

const FilterPage = (props: Props) => {
  const { name }: { name: string } = useParams();
  const filter: Filter | undefined = props.filters.find(
    (filter) => filter.name === name
  );
  const books: Book[] = filter
    ? props.books.filter((book) => filter.filter(book))
    : props.books;
  return (
    <Library
      collections={props.collections}
      books={books}
      title={filter?.name ?? "All"}
    />
  );
};

export default FilterPage;
