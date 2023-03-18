// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Box from "@mui/material/Box";
import type { History } from "history";
import { MutableRefObject, useCallback, useEffect, useRef } from "react";
import { useInView } from "react-intersection-observer";
import { useHistory } from "rocon/react";
import { Book } from "src/domain/book.ts";
import NavigationPage from "./NavigationPage.tsx";

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
    />
  );
};

const pages = (
  book: Book,
  history: History,
  refs: MutableRefObject<HTMLElement[]>
) => {
  return [...Array(book.pageCount).keys()].map((i: number) => (
    <Page key={i} index={i} book={book} history={history} refs={refs} />
  ));
};

const VerticalBookView = (props: Props) => {
  const refs = useRef<HTMLElement[]>([]);
  const history = useHistory();

  useEffect(() => {
    const pageIndex = parseInt(location.hash.substring(1));
    if (!isNaN(pageIndex) && refs.current && refs.current[pageIndex]) {
      refs.current[pageIndex].scrollIntoView();
      console.log(`scroll to ${pageIndex}`);
    } else if (refs.current && refs.current[0]) {
      refs.current[0].scrollIntoView();
      console.log("scroll to 0");
    } else {
      console.log("AAA");
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
