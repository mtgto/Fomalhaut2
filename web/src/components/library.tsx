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
import { Collection } from "../domain/collection";
import { Link as RouterLink } from "react-router-dom";

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
});

type Props = {
  collections: Collection[];
  books: Book[];
};

const Library = (props: Props) => {
  const classes = useStyles();
  return (
    <Layout collections={props.collections}>
      <Container maxWidth="md">
        <Box my={4}>
          <Typography variant="h4" component="h1" gutterBottom>
            Book shelf name {props.books.length}
          </Typography>
        </Box>
      </Container>
      <Container maxWidth="md">
        <Grid container spacing={4}>
          {props.books.map((book: Book) => (
            <Grid item key={book.id} xs={6} sm={4} md={3}>
              <Link component={RouterLink} to={`/books/${book.id}`}>
                <Card variant="outlined" className={classes.card}>
                  <CardMedia
                    component="img"
                    className={classes.media}
                    image={`/assets/books/${book.id}/thumbnail`}
                  />
                  <CardContent>
                    <Typography
                      gutterBottom
                      variant="caption"
                      className={classes.filename}
                      component="p"
                    >
                      {book.name}
                    </Typography>
                  </CardContent>
                </Card>
              </Link>
            </Grid>
          ))}
        </Grid>
      </Container>
    </Layout>
  );
};
export default Library;
