// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import { useContext, useEffect } from "react";
import { useNavigate } from "rocon/react";
import { Book } from "../domain/book";
import { Collection } from "../domain/collection";
import { setCurrentList, StateContext } from "../reducer";
import Library from "./Library";
import { collectionRoutes } from "./Routes";

type Props = {
  readonly id: string;
  readonly page?: number;
};

const CollectionPage: React.FunctionComponent<Props> = (props: Props) => {
  const { dispatch, state } = useContext(StateContext);
  const collection: Collection | undefined = state.collections.find(
    (collection) => collection.id === props.id
  );
  const navigate = useNavigate();
  useEffect(() => {
    if (collection) {
      document.title = `${collection.name} - Fomalhaut2`;
      dispatch(setCurrentList(collection.bookIds));
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [collection]);
  const books: Book[] =
    collection?.bookIds.flatMap(
      (bookId) => state.books.find((book) => book.id === bookId) ?? []
    ) ?? [];

  return (
    <Library
      id={props.id}
      books={books}
      title={collection?.name ?? "Loading"}
      page={props.page}
      pageChanged={(page) =>
        navigate(collectionRoutes.route, {
          id: props.id,
          page: page.toString(),
        })
      }
    />
  );
};

export default CollectionPage;
