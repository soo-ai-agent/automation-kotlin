import type {MouseEvent} from "react";
import {type ListState} from "../../common/lib/listState";
import {ListStatus} from "../../common/enums/listStatus";
import type {User} from "../types/user";
import {formatDateTime, formatOptionalDateTime} from "../../common/utils/formatDate";

type UserTableProps = {
    users: User[];
    isLoading: boolean;
    listState: ListState;
    selectedIds: number[];
    isAllSelected: boolean;
    isDeleting: boolean;
    toggleSelect: (id: number) => void;
    toggleSelectAll: () => void;
    openDetail: (id: number) => void;
    reloadUsers: () => Promise<void>;
    deleteOne: (id: number) => Promise<void>;
};

function UserTable({
    users,
    isLoading,
    listState,
    selectedIds,
    isAllSelected,
    isDeleting,
    toggleSelect,
    toggleSelectAll,
    openDetail,
    reloadUsers,
    deleteOne,
}: UserTableProps) {
    function stopRowClick(event: MouseEvent<HTMLElement>): void {
        event.stopPropagation();
    }

    if (isLoading) {
        return <p>사용자 목록을 불러오는 중입니다.</p>;
    }

    if (listState.status === ListStatus.ERROR) {
        return (
            <div>
                <p>{listState.message}</p>
                <button type="button" onClick={() => void reloadUsers()}>
                    다시 시도
                </button>
            </div>
        );
    }

    if (listState.status === ListStatus.EMPTY) {
        return <p>{listState.message}</p>;
    }

    return (
        <table>
            <thead>
                <tr>
                    <th scope="col">
                        <input
                            type="checkbox"
                            aria-label="전체 선택"
                            checked={isAllSelected}
                            onChange={toggleSelectAll}
                        />
                    </th>
                    <th scope="col">이름</th>
                    <th scope="col">이메일</th>
                    <th scope="col">가입일</th>
                    <th scope="col">마지막 로그인</th>
                    <th scope="col">관리</th>
                </tr>
            </thead>
            <tbody>
                {users.map((eachUser: User) => (
                    <tr key={eachUser.id} onClick={() => openDetail(eachUser.id)}>
                        <td onClick={stopRowClick}>
                            <input
                                type="checkbox"
                                aria-label={`${eachUser.name} 선택`}
                                checked={selectedIds.includes(eachUser.id)}
                                onChange={() => toggleSelect(eachUser.id)}
                            />
                        </td>
                        <td>
                            <button
                                type="button"
                                onClick={(event) => {
                                    stopRowClick(event);
                                    openDetail(eachUser.id);
                                }}
                            >
                                {eachUser.name}
                            </button>
                        </td>
                        <td>{eachUser.email}</td>
                        <td>{formatDateTime(eachUser.createdAt)}</td>
                        <td>{formatOptionalDateTime(eachUser.lastLoginAt)}</td>
                        <td>
                            <button
                                type="button"
                                disabled={isDeleting}
                                onClick={(event) => {
                                    stopRowClick(event);
                                    void deleteOne(eachUser.id);
                                }}
                            >
                                삭제
                            </button>
                        </td>
                    </tr>
                ))}
            </tbody>
        </table>
    );
}

export default UserTable;
