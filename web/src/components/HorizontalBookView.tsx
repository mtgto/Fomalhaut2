// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Box from "@mui/material/Box";
import type { History } from "history";
import { MutableRefObject, useEffect, useRef } from "react";
import { useInView } from "react-intersection-observer";
import { useHistory } from "rocon/react";
import { Book } from "../domain/book.ts";
import NavigationPage from "./NavigationPage.tsx";

type Props = Readonly<{
  book: Book;
  nextBook?: Book;
  direction: "left" | "right";
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
  const { ref } = useInView({
    onChange: (inView) => {
      if (inView) {
        props.history.replace({
          hash: props.index === 0 ? "" : `${props.index}`,
        });
      }
    },
  });
  return (
    <Box
      id={`${props.index}`}
      ref={(element: HTMLElement) =>
        (props.refs.current[props.index] = element)
      }
      display="flex"
      mx="auto"
      width="100%"
      height="100%"
      flexShrink={0}
      sx={{ scrollSnapAlign: "start" }}
      onClick={props.onClick}
    >
      <Box
        ref={ref}
        component="img"
        loading="lazy" // TODO: Load first 3 pages
        my="auto"
        mx="auto"
        maxHeight="100%"
        maxWidth="100%"
        src={`/images/books/${props.book.id}/pages/${props.index}`}
        display="block"
      />
    </Box>
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

  return [...Array(book.pageCount).keys()].map((i: number) => {
    return (
      <Page
        key={i}
        index={i}
        book={book}
        history={history}
        refs={refs}
        onClick={(e) => onClick(e, i)}
      />
    );
  });
};

const HorizontalBookView = (props: Props) => {
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
    <Box
      display="flex"
      flexDirection={props.direction === "right" ? "row" : "row-reverse"}
      sx={{
        width: "100%",
        height: "100vh",
        scrollSnapType: "x mandatory",
        overflowX: "auto",
      }}
    >
      {pages(props.book, history, refs)}
      <Box
        display="flex"
        flexDirection="column"
        width="100%"
        height="100%"
        flexShrink={0}
        justifyContent="center"
        alignItems="center"
        sx={{ scrollSnapAlign: "start" }}
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

export default HorizontalBookView;
