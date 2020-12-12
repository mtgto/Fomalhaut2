import React from "react";
import { Path, useRoutes } from "rocon/react";
import BookPage from "./Book";
import CollectionPage from "./Collection";
import FilterPage from "./Filter";

const bookRoutes = Path().any("id", {
  action: ({ id }) => <BookPage id={id} />,
});
const collectionRoutes = Path().any("id", {
  action: ({ id }) => <CollectionPage id={id} />,
});
const filterRoutes = Path().any("id", {
  action: ({ id }) => <FilterPage id={id} />,
});
export const topLevelRoutes = Path()
  .exact({
    action: () => <FilterPage id={undefined} />,
  })
  .route("books", (route) => route.attach(bookRoutes))
  .route("collections", (route) => route.attach(collectionRoutes))
  .route("filters", (route) => route.attach(filterRoutes));

const Routes: React.FC = () => {
  return useRoutes(topLevelRoutes);
};

export default Routes;
