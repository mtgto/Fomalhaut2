import React from "react";
import { Link as RouterLink } from "react-router-dom";

import ListItem from "@material-ui/core/ListItem";
import ListItemIcon from "@material-ui/core/ListItemIcon";
import ListItemText from "@material-ui/core/ListItemText";

type Props = {
  primary: string;
  to: string;
};

const ListItemLink = (props: Props) => {
  const renderLink = React.useMemo(
    () =>
      React.forwardRef<HTMLAnchorElement>((itemProps, ref) => (
        <RouterLink to={props.to} ref={ref} {...itemProps} />
      )),
    [props.to]
  );

  return (
    <li>
      <ListItem button component={renderLink}>
        {/* {icon ? <ListItemIcon>{icon}</ListItemIcon> : null} */}
        <ListItemText primary={props.primary} />
      </ListItem>
    </li>
  );
};

export default ListItemLink;
