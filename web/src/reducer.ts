// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import { createContext } from "react";

import { Book } from "./domain/book";
import { Collection } from "./domain/collection";
import { Filter } from "./domain/filter";

export const LoadingState = {
  Initial: 0,
  Loading: 1,
  Loaded: 2,
  Error: 3,
} as const;

type LoadingStateType = typeof LoadingState[keyof typeof LoadingState];

export interface State {
  readonly loading: LoadingStateType;
  readonly collections: Collection[];
  readonly filters: Filter[];
  readonly books: Book[];
}

const SetLoading = "SetLoading" as const;
const SetBooks = "SetBooks" as const;
const SetCollections = "SetCollections" as const;

type Actions =
  | ReturnType<typeof setLoading>
  | ReturnType<typeof setBooks>
  | ReturnType<typeof setCollections>;

export const setLoading = (LoadingState: LoadingStateType) => ({
  type: SetLoading,
  payload: LoadingState,
});

export const setCollections = (collections: Collection[]) => ({
  type: SetCollections,
  payload: collections,
});

export const setBooks = (books: Book[]) => ({
  type: SetBooks,
  payload: books,
});

export const initialState: State = {
  loading: LoadingState.Initial,
  collections: [],
  filters: [
    new Filter("all", "All", () => true),
    new Filter("unread", "Unread", (book: Book) => book.readCount === 0),
  ],
  books: [],
};

export const StateContext = createContext(initialState);

export const reducer = (state: State, action: Actions): State => {
  switch (action.type) {
    case SetLoading:
      return { ...state, loading: action.payload };
    case SetCollections:
      return { ...state, collections: action.payload };
    case SetBooks:
      return { ...state, books: action.payload };
    default:
      return initialState;
  }
};
