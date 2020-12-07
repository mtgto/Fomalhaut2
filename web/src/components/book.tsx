import React from "react";
import Box from "@material-ui/core/Box";
import Container from "@material-ui/core/Container";
import Link from "@material-ui/core/Link";
import Typography from "@material-ui/core/Typography";
import Grid from "@material-ui/core/Grid";
import Card from "@material-ui/core/Card";
import CardMedia from "@material-ui/core/CardMedia";
import CardContent from "@material-ui/core/CardContent";
import Layout from "./layout";
import makeStyles from "@material-ui/core/styles/makeStyles";
import { Book } from "../domain/book";
import { useParams } from "react-router-dom";
import { Collection } from "../domain/collection";

const useStyles = makeStyles({
  media: {
    height: 200,
    objectFit: "contain",
  },
  card: {
    //height: "100%",
  },
  filename: {
    display: "-webkit-box",
    WebkitLineClamp: 2,
    WebkitBoxOrient: "vertical",
    overflow: "hidden",
  },
  image: {
    width: "100%",
    maxWidth: "720px",
    display: "block",
    margin: "auto",
  },
});

const pages = (book: Book, classes: ReturnType<typeof useStyles>) => {
  return [...Array(book.pageCount).keys()].map((id: number) => (
    <img
      className={classes.image}
      key={id}
      src={`/assets/books/${book.id}/pages/${id}`}
    ></img>
  ));
};

type Props = {
  collections: Collection[];
  books: Book[];
};

const BookPage = (props: Props) => {
  const { id }: { id: string } = useParams();
  const classes = useStyles();
  const book: Book | undefined = props.books.find((book) => book.id === id);
  return (
    <Layout collections={props.collections}>
      <Container maxWidth="md">
        <Box mx="auto">
          {book ? pages(book, classes) : <span>Loading...</span>}
        </Box>
      </Container>
    </Layout>
  );
};
export default BookPage;
