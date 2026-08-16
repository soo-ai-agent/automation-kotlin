import {useCallback, useState} from "react";
import type {User} from "../types/user";

export function useUserSelection(users: User[]) {
    const [selectedIds, setSelectedIds] = useState<number[]>([]);

    const clearSelectedIds = useCallback((): void => {
        setSelectedIds([]);
    }, []);

    const toggleSelect = useCallback((id: number): void => {
        setSelectedIds((previousIds: number[]) => {
            if (previousIds.includes(id)) {
                return previousIds.filter((selectedId: number) => selectedId !== id);
            }
            return [...previousIds, id];
        });
    }, []);

    const toggleSelectAll = useCallback((): void => {
        setSelectedIds((previousIds: number[]) => {
            if (previousIds.length === users.length) {
                return [];
            }
            return users.map((eachUser: User) => eachUser.id);
        });
    }, [users]);

    const isAllSelected: boolean = users.length > 0 && selectedIds.length === users.length;

    return {selectedIds, isAllSelected, clearSelectedIds, toggleSelect, toggleSelectAll};
}
