import { Book } from "./domain/book";
import { Collection } from "./domain/collection";
import { Filter } from "./domain/filter";

export interface State {
  readonly collections: Collection[];
  readonly filters: Filter[];
  readonly books: Book[];
}

const SetBooks = "SetBooks" as const;
const SetCollections = "SetCollections" as const;

type Actions = ReturnType<typeof setBooks> | ReturnType<typeof setCollections>;

export const setCollections = (collections: Collection[]) => ({
  type: SetCollections,
  payload: collections,
});

export const setBooks = (books: Book[]) => ({
  type: SetBooks,
  payload: books,
});

export const initialState: State = {
  collections: [],
  filters: [new Filter("All"), new Filter("Unread")],
  books: [],
};

export const reducer = (state: State, action: Actions): State => {
  switch (action.type) {
    case SetCollections:
      return { ...state, collections: action.payload };
    case SetBooks:
      return { ...state, books: action.payload };
    default:
      return initialState;
  }
};
