// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Box from "@mui/material/Box";
import type { History } from "history";
import { MutableRefObject, useCallback, useEffect, useRef } from "react";
import { useInView } from "react-intersection-observer";
import { useHistory } from "rocon/react";
import { Book } from "../domain/book";
import NavigationPage from "./NavigationPage";

type Props = Readonly<{
  book: Book;
  nextBook?: Book;
  onNext: () => void;
  onRandom: () => void;
}>;

const Page = (
  props: Readonly<{
    index: number;
    book: Book;
    history: History;
    refs: MutableRefObject<HTMLElement[]>;
    onClick: (e: React.MouseEvent) => void;
  }>
) => {
  const { ref: inViewRef } = useInView({
    onChange: (inView) => {
      if (inView) {
        props.history.replace({
          hash: props.index === 0 ? "" : `${props.index}`,
        });
      }
    },
  });
  const setRefs = useCallback(
    (element: HTMLElement) => {
      props.refs.current[props.index] = element;
      inViewRef(element);
    },
    [inViewRef, props]
  );
  return (
    <Box
      ref={setRefs}
      component="img"
      loading="lazy" // TODO: Load first 3 pages
      my={1}
      mx="auto"
      display="block"
      width="100%"
      maxWidth="720px"
      minHeight="200px"
      src={`/images/books/${props.book.id}/pages/${props.index}`}
      onClick={props.onClick}
    />
  );
};

const pages = (
  book: Book,
  history: History,
  refs: MutableRefObject<HTMLElement[]>
) => {
  const onClick = (e: React.MouseEvent, page: number) => {
    if (e.shiftKey) {
      if (page > 0) {
        refs.current[page - 1].scrollIntoView({ behavior: "smooth" });
      }
    } else {
      if (refs.current.length > page + 1) {
        refs.current[page + 1].scrollIntoView({ behavior: "smooth" });
      }
    }
  };
  return [...Array(book.pageCount).keys()].map((i: number) => (
    <Page
      key={i}
      index={i}
      book={book}
      history={history}
      refs={refs}
      onClick={(e) => onClick(e, i)}
    />
  ));
};

const VerticalBookView = (props: Props) => {
  const refs = useRef<HTMLElement[]>([]);
  const history = useHistory();

  useEffect(() => {
    const pageIndex = parseInt(location.hash.substring(1));
    if (!isNaN(pageIndex) && refs.current && refs.current[pageIndex]) {
      refs.current[pageIndex].scrollIntoView();
    } else if (refs.current && refs.current[0]) {
      refs.current[0].scrollIntoView();
    }
  }, [props.book]);

  return (
    <Box mx="auto">
      {pages(props.book, history, refs)}
      <Box
        display="flex"
        flexDirection="column"
        justifyContent="center"
        alignItems="center"
        width="100%"
        height="100vh"
      >
        <NavigationPage
          book={props.book}
          nextBook={props.nextBook}
          onNext={props.onNext}
          onRandom={props.onRandom}
        />
      </Box>
    </Box>
  );
};

export default VerticalBookView;
