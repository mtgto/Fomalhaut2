// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import React, { useContext } from "react";
import { StateContext } from "../reducer";

import { Book } from "../domain/book";
import { Filter } from "../domain/filter";
import Library from "./Library";

type Props = {
  readonly id: string | undefined;
};

const FilterPage = (props: Props) => {
  const state = useContext(StateContext);
  const filter: Filter | undefined = state.filters.find(
    (filter) => filter.id === props.id
  );
  const books: Book[] = filter
    ? state.books.filter((book) => filter.filter(book))
    : state.books;
  return <Library books={books} title={filter?.name ?? "All"} />;
};

export default FilterPage;
