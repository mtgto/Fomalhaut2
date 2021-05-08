// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import { useContext, useEffect } from "react";
import { useNavigate } from "rocon/react";
import { Book } from "../domain/book";
import { Filter } from "../domain/filter";
import { message } from "../message";
import { setCurrentList, StateContext } from "../reducer";
import Library from "./Library";
import { filterRoutes } from "./Routes";

type Props = {
  readonly id: string;
  readonly page?: number;
};

const FilterPage: React.VoidFunctionComponent<Props> = (props: Props) => {
  const { dispatch, state } = useContext(StateContext);
  const filter: Filter | undefined = state.filters.find(
    (filter) => filter.id === props.id
  );
  const books: ReadonlyArray<Book> = filter
    ? state.books.filter((book) => filter.filter(book))
    : state.books;
  const navigate = useNavigate();
  useEffect(() => {
    if (filter) {
      document.title = `${filter.name} - Fomalhaut2`;
      dispatch(setCurrentList(books.map((book) => book.id)));
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filter, books.map((book) => book.id).join(",")]);
  return (
    <Library
      books={books}
      title={filter?.name ?? message.filter.all}
      page={props.page}
      pageChanged={(page) =>
        navigate(filterRoutes.route, { id: props.id, page: page.toString() })
      }
    />
  );
};

export default FilterPage;
