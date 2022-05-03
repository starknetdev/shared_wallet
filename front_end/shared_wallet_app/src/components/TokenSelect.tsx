import { useState } from "react";
import {
    Fab,
    List,
    ListItem,
    Dialog,
    DialogTitle
} from "@mui/material";
// import ArrowDropDownIcon from '@mui/icons-material/ArrowDropDown';
import { LiquidityPair } from "../features/Main";
import { TokenListItem } from "./TokenListItem";

interface TokenSelectInputProps {
    label?: string;
    id?: string;
    supportedTokens: Array<LiquidityPair>;
    liquidityToken: LiquidityPair | undefined;
    onChange: (liquidityToken: LiquidityPair | undefined) => void;
    disabled?: boolean;
    [x: string]: any;
}

interface SimpleDialogProps {
    open: boolean;
    selectedValue: LiquidityPair | undefined;
    onClose: (liquidityToken: LiquidityPair | undefined) => void;
    supportedTokens: Array<LiquidityPair>;
}

const SimpleDialog = (props: SimpleDialogProps) => {

    const { onClose, selectedValue, open, supportedTokens } = props;

    const handleClose = () => {
        onClose(selectedValue);
    };

    const handleListItemClick = (liquidityToken: LiquidityPair | undefined) => {
        onClose(liquidityToken);
    };

    return (
        <Dialog
            onClose={handleClose}
            open={open}
            maxWidth="xs"
            fullWidth={true}
        >
            <DialogTitle>Select Token</DialogTitle>
            <List>
                {supportedTokens.map((token) => (
                    <ListItem button onClick={() => handleListItemClick(token)} key={token.name}>
                        <TokenListItem token={token} />
                    </ListItem>
                ))}
            </List>
        </Dialog>
    )
}

export const TokenSelect = ({
    label = "Token Select",
    id = "token-select",
    supportedTokens,
    liquidityToken,
    onChange,
    disabled = false,
    ...rest
}: TokenSelectInputProps) => {

    const [open, setOpen] = useState(false);
    const [selectedValue, setSelectedValue] = useState<LiquidityPair>();


    const handleClickOpen = () => {
        setOpen(true);
    };

    const handleClose = (liquidityToken: LiquidityPair | undefined) => {
        setOpen(false);
        setSelectedValue(liquidityToken);
        onChange(liquidityToken);
    }

    return (
        <div>
            <div className="liquidity-token-select-button">
                {selectedValue ? (
                    <Fab
                        onClick={handleClickOpen}
                        variant="extended"
                        size="large">
                        <div className="liquidity-button-content">
                            <img className="liquidity-button-image" src={selectedValue.image} alt={selectedValue.name} />
                            {selectedValue.name}
                        </div>
                    </Fab>
                ) : (
                    <Fab
                        onClick={handleClickOpen}
                        variant="extended"
                        color="secondary">
                        Select Token
                    </Fab>
                )}
            </div>
            <SimpleDialog
                selectedValue={selectedValue}
                open={open}
                onClose={handleClose}
                // onChange={handleSelectChange}
                supportedTokens={supportedTokens}
            />
        </div>
    )
}