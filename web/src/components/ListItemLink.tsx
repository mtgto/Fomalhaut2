import ListItemButton from "@mui/material/ListItemButton";
import ListItemText from "@mui/material/ListItemText";
import { forwardRef, useMemo } from "react";
import { Link as RoconLink } from "rocon/react";
import { collectionRoutes, filterRoutes } from "./Routes";

type Props = {
  primary: string;
  route: typeof collectionRoutes.route | typeof filterRoutes.route;
  match: { readonly id: string };
};

const ListItemLink = (props: Props) => {
  const renderLink = useMemo(
    () =>
      forwardRef<HTMLAnchorElement, unknown>(function Link(itemProps, ref) {
        return (
          <RoconLink
            route={props.route}
            match={props.match}
            ref={ref}
            {...itemProps}
          />
        );
      }),
    [props.match, props.route]
  );

  return (
    <li>
      <ListItemButton component={renderLink}>
        <ListItemText primary={props.primary} />
      </ListItemButton>
    </li>
  );
};

export default ListItemLink;
