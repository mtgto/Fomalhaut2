// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import React, { createContext } from "react";
import { Book } from "./domain/book";
import { Collection } from "./domain/collection";
import { Filter } from "./domain/filter";
import { message } from "./message";

export const LoadingState = {
  Initial: 0,
  Loading: 1,
  Loaded: 2,
  Error: 3,
} as const;

type LoadingStateType = typeof LoadingState[keyof typeof LoadingState];

export interface State {
  readonly loading: LoadingStateType;
  readonly collections: ReadonlyArray<Collection>;
  readonly filters: ReadonlyArray<Filter>;
  readonly books: ReadonlyArray<Book>;
  readonly selectedBookIds: ReadonlyArray<string>;
}

const SetLoading = "SetLoading" as const;
const SetBooks = "SetBooks" as const;
const SetCollections = "SetCollections" as const;
const ToggleLike = "ToggleLike" as const;
const SetCurrentList = "SetCurrentList" as const;

type Actions =
  | ReturnType<typeof setLoading>
  | ReturnType<typeof setBooks>
  | ReturnType<typeof setCollections>
  | ReturnType<typeof toggleLike>
  | ReturnType<typeof setCurrentList>;

// eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
export const setLoading = (LoadingState: LoadingStateType) => ({
  type: SetLoading,
  payload: LoadingState,
});

// eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
export const setCollections = (collections: Collection[]) => ({
  type: SetCollections,
  payload: collections,
});

// eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
export const setBooks = (books: Book[]) => ({
  type: SetBooks,
  payload: books,
});

// eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
export const toggleLike = (bookId: string) => ({
  type: ToggleLike,
  payload: bookId,
});

export const setCurrentList = (selectedBookIds: ReadonlyArray<string>) => ({
  type: SetCurrentList,
  payload: selectedBookIds,
});

export const initialState: State = {
  loading: LoadingState.Initial,
  collections: [],
  filters: [
    new Filter("all", message.filter.all, () => true),
    new Filter(
      "unread",
      message.filter.unread,
      (book: Book) => book.readCount === 0
    ),
    new Filter("like", message.filter.like, (book: Book) => book.like),
  ],
  books: [],
  selectedBookIds: [],
};

export const StateContext = createContext<{
  state: State;
  dispatch: React.Dispatch<Actions>;
}>({ state: initialState, dispatch: () => null });

export const reducer = (state: State, action: Actions): State => {
  switch (action.type) {
    case SetLoading:
      return { ...state, loading: action.payload };
    case SetCollections:
      return { ...state, collections: action.payload };
    case SetBooks:
      return { ...state, books: action.payload };
    case ToggleLike:
      return {
        ...state,
        books: state.books.map((book) =>
          book.id === action.payload ? { ...book, like: !book.like } : book
        ),
      };
    case SetCurrentList:
      return {
        ...state,
        selectedBookIds: action.payload,
      };
    default:
      return initialState;
  }
};
