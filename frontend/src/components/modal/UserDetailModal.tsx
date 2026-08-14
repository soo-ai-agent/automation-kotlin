import {forwardRef, useImperativeHandle, type MouseEvent, type Ref} from "react";
import {useUserDetail} from "../../hooks/useUserDetail";
import {DetailStatus} from "../../enums/user";
import {useServiceErrorHandler} from "../../hooks/useServiceErrorHandler";
import {formatDateTime, formatOptionalDateTime} from "../../utils/formatDate";

/** 부모에게서 받는 값이 없다. 여는 것은 ref 의 openDetail 이 한다. */
type UserDetailModalProps = Record<never, never>;

export interface UserDetailModalRef {
    openDetail: (id: number) => void;
}

function UserDetailModal(_props: UserDetailModalProps, ref: Ref<UserDetailModalRef>) {
    const {handleError} = useServiceErrorHandler();
    const {detailState, openDetail, closeDetail} = useUserDetail(handleError);

    useImperativeHandle(ref, () => ({openDetail}), [openDetail]);

    function stopBackdropClose(event: MouseEvent<HTMLDivElement>): void {
        event.stopPropagation();
    }

    if (detailState.status === DetailStatus.CLOSED) {
        return null;
    }

    return (
        <div role="presentation" onClick={closeDetail}>
            <div
                role="dialog"
                aria-modal="true"
                aria-label="사용자 상세"
                onClick={stopBackdropClose}
            >
                {detailState.status === DetailStatus.LOADING && <p>사용자 정보를 불러오는 중입니다.</p>}

                {detailState.status === DetailStatus.LOADED && (
                    <article>
                        <h2>{detailState.user.name}</h2>
                        <dl>
                            <dt>이메일</dt>
                            <dd>{detailState.user.email}</dd>
                            <dt>가입일</dt>
                            <dd>{formatDateTime(detailState.user.createdAt)}</dd>
                            <dt>마지막 로그인</dt>
                            <dd>{formatOptionalDateTime(detailState.user.lastLoginAt)}</dd>
                        </dl>
                    </article>
                )}

                <button type="button" onClick={closeDetail}>
                    닫기
                </button>
            </div>
        </div>
    );
}

export default forwardRef(UserDetailModal);
